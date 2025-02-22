class PlanSelection
  attr_reader :plan, :hbx_enrollment

  def initialize(enrollment, pl)
    @hbx_enrollment = enrollment
    @plan = pl
  end

  def employee_is_shopping_before_hire?
    hbx_enrollment.employee_role.present? && hbx_enrollment.employee_role.hired_on > TimeKeeper.date_of_record
  end

  def may_select_coverage?
    hbx_enrollment.may_select_coverage?
  end

  def apply_aptc_if_needed(elected_aptc, max_aptc)
    decorated_plan = UnassistedPlanCostDecorator.new(plan, hbx_enrollment, elected_aptc)
    hbx_enrollment.update_hbx_enrollment_members_premium(decorated_plan)
    hbx_enrollment.update_attributes!(applied_aptc_amount: decorated_plan.total_aptc_amount, elected_aptc_pct: elected_aptc / max_aptc, ehb_premium: decorated_plan.total_ehb_premium)
  end

  # FIXME: Needs to deactivate the parent enrollment, also, we set the sep here? WAT
  def select_plan_and_deactivate_other_enrollments(previous_enrollment_id, market_kind)
    hbx_enrollment.update_attributes!(product_id: plan.id, issuer_profile_id: plan.issuer_profile_id)
    qle = hbx_enrollment.is_special_enrollment?
    if qle
      hbx_enrollment.special_enrollment_period_id = hbx_enrollment.earlier_effective_sep_by_market_kind.try(:id)
    end

    hbx_enrollment.aasm_state = 'actively_renewing' if hbx_enrollment.is_active_renewal_purchase?

    hbx_enrollment.update_attributes!(is_any_enrollment_member_outstanding: true) if enrollment_members_verification_status(market_kind)

    hbx_enrollment.select_coverage!(qle: qle) if may_select_coverage?
  end

  def enrollment_members_verification_status(market_kind)
    members = hbx_enrollment.hbx_enrollment_members.flat_map(&:person).flat_map(&:consumer_role)
    if market_kind == "individual"
      return  (members.compact.present? && (members.any?(&:verification_outstanding?) || members.any?(&:verification_period_ended?)))
    else
      return false
    end
  end

  def self.for_enrollment_id_and_plan_id(enrollment_id, plan_id)
    plan = BenefitMarkets::Products::Product.find(plan_id)
    hbx_enrollment = HbxEnrollment.find(enrollment_id)
    self.new(hbx_enrollment, plan)
  end

  def family
    hbx_enrollment.family
  end

  def verify_and_set_member_coverage_start_dates
    if existing_coverage.present? && (existing_coverage.product_id == plan.id)
      set_enrollment_member_coverage_start_dates(hbx_enrollment)
      hbx_enrollment.predecessor_enrollment_id = existing_coverage._id unless hbx_enrollment.is_shop?
    end
  end

  def same_plan_enrollment
    return @same_plan_enrollment if defined? @same_plan_enrollment

    @same_plan_enrollment = family.active_household.hbx_enrollments.new(hbx_enrollment.dup.attributes)
    @same_plan_enrollment.hbx_enrollment_members = build_hbx_enrollment_members
    @same_plan_enrollment = set_enrollment_member_coverage_start_dates(@same_plan_enrollment)

    update_tax_household_enrollments
    @same_plan_enrollment
  end

  # Update only if TaxHouseholdMemberEnrollmentMember exists and the bson_id is different.
  def update_tax_household_enrollments
    member_applicant_ids = @same_plan_enrollment.hbx_enrollment_members.map(&:applicant_id)
    return if member_applicant_ids.blank?

    th_enrollments = TaxHouseholdEnrollment.where(enrollment_id: hbx_enrollment.id)
    th_enrollments.each do |th_enr|
      th_enr.tax_household_members_enrollment_members.each do |thh_enr_member|
        enr_member_id = @same_plan_enrollment.hbx_enrollment_members.where(applicant_id: thh_enr_member.family_member_id).first.id
        thh_enr_member.hbx_enrollment_member_id = enr_member_id if enr_member_id.present? && thh_enr_member.hbx_enrollment_member_id != enr_member_id
      end
      th_enr.save!
    end
  rescue StandardError => e
    Rails.logger.error "Error raised while update_tax_household_enrollments message: #{e}, backtrace: #{e.backtrace.join('\n')}"
  end

  def build_hbx_enrollment_members
    hbx_enrollment.hbx_enrollment_members.collect do |hbx_enrollment_member|
      HbxEnrollmentMember.new({
        applicant_id: hbx_enrollment_member.applicant_id,
        eligibility_date: hbx_enrollment.effective_on,
        coverage_start_on: hbx_enrollment.effective_on,
        is_subscriber: hbx_enrollment_member.is_subscriber,
        tobacco_use: hbx_enrollment_member.tobacco_use
      })
    end
  end

  def existing_coverage
    if hbx_enrollment.is_shop?
      @hbx_enrollment.parent_enrollment
    else
      existing_enrollment_for_covered_individuals
    end
  end

  def set_enrollment_member_coverage_start_dates(enrollment_obj = hbx_enrollment)
    if existing_coverage.present?
      previous_enrollment_members = existing_coverage.hbx_enrollment_members

      enrollment_obj.hbx_enrollment_members.each do |member|
        matched = previous_enrollment_members.detect{|enrollment_member| enrollment_member.hbx_id == member.hbx_id}

        if matched
          member.coverage_start_on = matched.coverage_start_on || existing_coverage.effective_on
        end
      end
    end

    enrollment_obj
  end

  # for IVL market, we need to compare hios_ids instead of product IDs
  def existing_enrollment_for_covered_individuals
    family.current_enrolled_or_termed_coverages(hbx_enrollment).detect do |en|
      (en.hbx_enrollment_members.collect(&:hbx_id) & hbx_enrollment.hbx_enrollment_members.collect(&:hbx_id)).present? &&
        (plan.present? ? plan.is_same_plan_by_hios_id_and_active_year?(en.product) : false)
    end
  end

  def family
    @hbx_enrollment.family
  end
end
