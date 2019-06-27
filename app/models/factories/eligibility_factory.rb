# frozen_string_literal: true

module Factories
  class EligibilityFactory

    def initialize(enrollment_id, selected_aptc = nil, product_ids = [])
      @enrollment = HbxEnrollment.find(enrollment_id)
      raise "Cannot find a valid enrollment with given enrollment id" unless @enrollment

      @family = @enrollment.family
      set_applicable_aptc_attrs(selected_aptc, product_ids) if product_ids.present? && selected_aptc
    end

    # returns hash of total_aptc, aptc_breakdown_by_member and csr_value
    def fetch_available_eligibility
      available_eligibility_hash = fetch_enrolling_available_aptcs.merge(fetch_csr)
      total_aptc = available_eligibility_hash[:aptc].values.inject(0, :+)
      available_eligibility_hash.merge({:total_available_aptc => total_aptc})
    end

    # returns hash of product_id to applicable_aptc mappings
    def fetch_applicable_aptcs
      raise "Cannot process without #{@selected_aptc} and #{@product_ids}" if @selected_aptc.nil? || @product_ids.empty?

      # TODO: Return a has of plan_id, applicable aptcs.
      @product_ids.inject({}) do |products_aptcs_hash, product_id|
        product_aptc = applicable_aptc_hash(product_id)
        products_aptcs_hash.merge!(product_aptc) unless product_aptc.empty?
        products_aptcs_hash
      end
    end

    private

    def applicable_aptc_hash(product_id)
      applicable_aptc = [@selected_aptc, ehb_premium(product_id)].min
      { product_id => applicable_aptc }
    end

    def set_applicable_aptc_attrs(selected_aptc, product_ids)
      @selected_aptc = selected_aptc
      @product_ids = product_ids
    end

    def ehb_premium(product_id)
      premium_amount = fetch_total_premium(product_id)
      product = ::BenefitMarkets::Products::Product.find(product_id)
      @ehb_premium = premium_amount * product.ehb.round(2)
    end

    def fetch_total_premium(product_id)
      @cost_decorator = @enrollment.ivl_decorated_hbx_enrollment(product_id)
      @cost_decorator.total_premium
    end

    def shopping_member_ids
      @enrollment.hbx_enrollment_members.pluck(:applicant_id).map(&:to_s)
    end

    def tax_households
      @family.active_household.latest_active_tax_household_with_year(@enrollment.effective_on.year).to_a
    end

    def shopping_tax_members
      tax_households.flat_map(&:tax_household_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
    end

    def any_aptc_ineligible?
      shopping_tax_members.map(&:is_ia_eligible?).include?(false)
    end

    def aptc_enrollment_members(aptc_thhms)
      aptc_thhms.select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) && thhm.is_ia_eligible? }
    end

    def enrollment_eligible_benchmark_hash(aptc_thhms)
      aptc_thhms.inject({}) do |benchmark_hash, thhm|
        benchmark_hash.merge!({ thhm.applicant_id.to_s => thhm.family_member.aptc_benchmark_amount })
      end
    end

    def tax_members_aptc_breakdown(tax_household)
      total_thh_available_aptc = tax_household.total_aptc_available_amount_for_enrollment(@enrollment)
      aptc_thhms = tax_household.aptc_members
      member_aptc_benchmark_hash = enrollment_eligible_benchmark_hash(aptc_thhms)
      total_eligible_member_benchmark = member_aptc_benchmark_hash.values.sum
      enrolling_aptc_members = aptc_enrollment_members(aptc_thhms)

      enrolling_aptc_members.inject({}) do |thh_hash, thh_member|
        fm_id = thh_member.applicant_id.to_s
        member_ratio = (member_aptc_benchmark_hash[fm_id] / total_eligible_member_benchmark)
        thh_hash.merge!({ fm_id => (total_thh_available_aptc * member_ratio) })
      end
    end

    def fetch_enrolling_available_aptcs
      # 1. What if one of the shopping members does not exist in any tax_households

      aptc_breakdowns = tax_households.inject({}) do |tax_members_aptcs, tax_household|
        aptc_hash = tax_members_aptc_breakdown(tax_household)
        tax_members_aptcs.merge!(aptc_hash) unless aptc_hash.empty?
        tax_members_aptcs
      end

      { :aptc => aptc_breakdowns}
    end

    def prioritized_csr(csr_kinds)
      if csr_kinds.include?('csr_100')
        'csr_100'
      elsif csr_kinds.include?('csr_94')
        'csr_94'
      elsif csr_kinds.include?('csr_87')
        'csr_87'
      elsif csr_kinds.include?('csr_73')
        'csr_73'
      else
        'csr_0'
      end
    end

    def fetch_csr
      return {:csr => 'csr_100'} if (shopping_tax_members.count != shopping_member_ids.count) || any_aptc_ineligible?

      csr_kinds = tax_households.map(&:current_csr_eligibility_kind)
      {:csr => prioritized_csr(csr_kinds)}
    end
  end
end
