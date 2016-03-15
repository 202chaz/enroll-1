module Employers::EmployerHelper
  def address_kind
    @family.try(:census_employee).try(:address).try(:kind) || 'home'
  end

  def enrollment_state(census_employee=nil)
    return "" if census_employee.blank?

    enrollment_state = census_employee.active_benefit_group_assignment.try(:aasm_state)
    if enrollment_state.present? and enrollment_state != "initialized"
      enrollment_state.humanize
    else
      ""
    end
  end

  def render_plan_offerings(benefit_group, coverage_type)
    reference_plan = benefit_group.reference_plan
    if coverage_type == ".dental" && benefit_group.single_plan_type?
      plan_count = benefit_group.elected_dental_plan_ids.count
      "#{plan_count} Plans"
    elsif coverage_type == ".dental" && benefit_group.plan_option_kind == "single_carrier"
      plan_count = Plan.shop_dental_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
      "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
    else
      return "1 Plan Only" if benefit_group.single_plan_type?
      if benefit_group.plan_option_kind == "single_carrier"
        plan_count = Plan.shop_health_by_active_year(reference_plan.active_year).by_carrier_profile(reference_plan.carrier_profile).count
        "All #{reference_plan.carrier_profile.legal_name} Plans (#{plan_count})"
      else
        plan_count = Plan.shop_health_by_active_year(reference_plan.active_year).by_health_metal_levels([reference_plan.metal_level]).count
        "#{reference_plan.metal_level.titleize} Plans (#{plan_count})"
      end
    end
  end


  def get_benefit_groups_for_census_employee
    # if @employer_profile.active_plan_year.blank?
    #   return [], []
    # end

    all_benefit_groups = @employer_profile.plan_years.select{|py| !py.renewing_draft? }.map(&:benefit_groups).try(:flatten)
    if all_benefit_groups.empty?
      return [], []
    end

    current_benefit_groups = all_benefit_groups #@employer_profile.active_plan_year.benefit_groups
    renewing_benefit_groups = @employer_profile.renewing_plan_year.benefit_groups if @employer_profile.renewing_plan_year
    return current_benefit_groups, renewing_benefit_groups || []
  end
end
