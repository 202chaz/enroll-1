# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      module Transformers
        module ApplicationTo
          # Application params to be transformed.
          class Cv3Application
            # constructs cv3 payload for medicaid gateway.

            send(:include, Dry::Monads[:result, :do])
            include Acapi::Notifiers
            require 'securerandom'

            # @param [ Hash ] params Applicant Attributes
            # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
            def call(application)
              application = yield validate(application)
              request_payload = yield construct_payload(application)

              Success(request_payload)
            end

            private

            def validate(application)
              return Success(application) if application.submitted?
              Failure("Application is in #{application.aasm_state} state. Please submit application.")
            end

            def construct_payload(application)
              payload = {family_reference: {hbx_id: find_family(application.family_id)},
                         assistance_year: application.assistance_year,
                         aptc_effective_date: application.effective_date,
                         years_to_renew: application.renewal_base_year,
                         renewal_consent_through_year: application.years_to_renew,
                         is_ridp_verified: application.is_ridp_verified,
                         is_renewal_authorized: application.is_renewal_authorized,
                         applicants: applicants(application),
                         relationships: application_relationships(application),
                         tax_households: tax_households(application),
                         us_state: application.us_state,
                         hbx_id: application.hbx_id,
                         oe_start_on: application.effective_date, # what is the date here for required field? # check with sarah
                         mitc_households: mitc_households(application),
                         mitc_tax_returns: mitc_tax_returns(application)}
              Success(payload)
            end

            def find_family(family_id)
              ::Family.find(family_id)&.hbx_assigned_id.to_s
            end

            def applicants(application)
              applicants = application.applicants.inject([]) do |result, applicant|
                result << {name: {first_name: applicant.first_name,
                                  middle_name: applicant.middle_name,
                                  last_name: applicant.last_name,
                                  name_sfx: applicant.name_sfx,
                                  name_pfx: applicant.name_pfx},
                           identifying_information: {has_ssn: applicant.no_ssn,
                                                     encrypted_ssn: applicant.encrypted_ssn},
                           demographic: {gender: applicant.gender.capitalize,
                                         dob: applicant.dob,
                                         ethnicity: applicant.ethnicity,
                                         race: applicant.race,
                                         is_veteran_or_active_military: applicant.is_veteran_or_active_military,
                                         is_vets_spouse_or_child: applicant.is_vets_spouse_or_child},
                           attestation: {is_incarcerated: applicant.is_incarcerated,
                                         is_self_attested_disabled: applicant.is_self_attested_disabled,
                                         is_self_attested_blind: applicant.is_self_attested_blind,
                                         is_self_attested_long_term_care: applicant.is_self_attested_long_term_care},
                           is_primary_applicant: applicant.is_primary_applicant,
                           native_american_information: {indian_tribe_member: applicant.indian_tribe_member,
                                                         tribal_id: applicant.tribal_id},
                           citizenship_immigration_status_information: {citizen_status: applicant.citizen_status,
                                                                        is_resident_post_092296: applicant.is_resident_post_092296},
                           is_consumer_role: applicant.is_consumer_role,
                           is_resident_role: applicant.is_resident_role,
                           is_applying_coverage: applicant.is_applying_coverage,
                           is_consent_applicant: applicant.is_consent_applicant,
                           vlp_document: vlp_document(applicant),
                           family_member_reference: {family_member_hbx_id: applicant.person_hbx_id.to_s},
                           person_hbx_id: applicant.person_hbx_id.to_s,
                           is_required_to_file_taxes: applicant.is_required_to_file_taxes,
                           is_joint_tax_filing: applicant.is_joint_tax_filing,
                           is_claimed_as_tax_dependent: applicant.is_claimed_as_tax_dependent,
                           claimed_as_tax_dependent_by: applicant.claimed_as_tax_dependent_by,
                           tax_filer_kind: applicant.tax_filer_kind,
                           student: {is_student: applicant.is_student,
                                     student_kind: applicant.student_kind,
                                     student_school_kind: applicant.student_school_kind,
                                     student_status_end_on: applicant.student_status_end_on},
                           is_refugee: applicant.is_refugee,
                           is_trafficking_victim: applicant.is_trafficking_victim,
                           foster_care: {is_former_foster_care: applicant.is_former_foster_care,
                                         age_left_foster_care: applicant.age_left_foster_care,
                                         foster_care_us_state: applicant.foster_care_us_state,
                                         had_medicaid_during_foster_care: applicant.had_medicaid_during_foster_care},
                           pregnancy_information: {is_pregnant: applicant.is_pregnant,
                                                   is_enrolled_on_medicaid: applicant.is_enrolled_on_medicaid,
                                                   is_post_partum_period: applicant.is_post_partum_period,
                                                   expected_children_count: applicant.children_expected_count,
                                                   pregnancy_due_on: applicant.pregnancy_due_on,
                                                   pregnancy_end_on: applicant.pregnancy_end_on},
                           is_subject_to_five_year_bar: applicant.is_subject_to_five_year_bar,
                           is_five_year_bar_met: applicant.is_five_year_bar_met,
                           is_forty_quarters: applicant.is_forty_quarters,
                           is_ssn_applied: applicant.is_ssn_applied,
                           non_ssn_apply_reason: applicant.non_ssn_apply_reason,
                           moved_on_or_after_welfare_reformed_law: applicant.moved_on_or_after_welfare_reformed_law,
                           is_currently_enrolled_in_health_plan: applicant.is_currently_enrolled_in_health_plan,
                           has_daily_living_help: applicant.has_daily_living_help,
                           need_help_paying_bills: applicant.need_help_paying_bills,
                           has_job_income: applicant.has_job_income,
                           has_self_employment_income: applicant.has_self_employment_income,
                           has_unemployment_income: applicant.has_unemployment_income,
                           has_other_income: applicant.has_other_income,
                           has_deductions: applicant.has_deductions,
                           has_enrolled_health_coverage: applicant.has_enrolled_health_coverage,
                           has_eligible_health_coverage: applicant.has_eligible_health_coverage,
                           job_coverage_ended_in_past_3_months: applicant.has_dependent_with_coverage,
                           job_coverage_end_date: applicant.dependent_job_end_on,
                           medicaid_and_chip: {not_eligible_in_last_90_days: applicant.has_eligible_medicaid_cubcare,
                                               denied_on: applicant.medicaid_cubcare_due_on,
                                               ended_as_change_in_eligibility: applicant.has_eligibility_changed,
                                               hh_income_or_size_changed: applicant.has_household_income_changed,
                                               medicaid_or_chip_coverage_end_date: applicant.person_coverage_end_on,
                                               ineligible_due_to_immigration_in_last_5_years: applicant.medicaid_chip_ineligible,
                                               immigration_status_changed_since_ineligibility: applicant.immigration_status_changed,},
                           other_health_service: {has_received: applicant.health_service_through_referral,
                                                  is_eligible: applicant.health_service_eligible},
                           addresses: addresses(applicant),
                           emails: emails(applicant),
                           phones: phones(applicant),
                           incomes: incomes(applicant),
                           benefits: benefits(applicant),
                           deductions: deductions(applicant),
                           is_medicare_eligible: applicant.is_medicare_eligible,
                           is_self_attested_long_term_care: applicant.is_self_attested_long_term_care,
                           has_insurance: applicant.is_enrolled_in_insurance?,
                           has_state_health_benefit: applicant.has_state_health_benefit?,
                           had_prior_insurance: had_prior_insurance?(applicant),
                           prior_insurance_end_date: applicant.prior_insurance_end_date,
                           age_of_applicant: applicant.age_of_the_applicant,
                           hours_worked_per_week: applicant.total_hours_worked_per_week,
                           is_temporarily_out_of_state: applicant.is_temporarily_out_of_state,
                           is_claimed_as_dependent_by_non_applicant: false, # as per sb notes
                           benchmark_premium: applicant_benchmark_premium(application), #applicant_benchmark_premium(applicant.application),
                           is_homeless: applicant.is_homeless,
                           mitc_income: mitc_income(applicant),
                           mitc_relationships: []}
                result
              end
              applicants
            end

            def mitc_income(applicant)
              { amount: 0, #TODO
                taxable_interest: taxable_interest(applicant),
                tax_exempt_interest: 0,
                taxable_refunds: 0,
                alimony: alimony(applicant),
                capital_gain_or_loss: capital_gain_or_loss(applicant),
                pensions_and_annuities_taxable_amount: pensions_and_annuities_taxable_amount(applicant),
                farm_income_or_loss: farm_income_or_loss(applicant),
                unemployment_compensation: unemployment_compensation(applicant),
                other_income: other_income(applicant),
                magi_deductions: magi_deductions(applicant),
                adjusted_gross_income: 0, #TODO
                deductible_part_of_self_employment_tax: deductible_part_of_self_employment_tax(applicant),
                ira_deduction: ira_deduction(applicant),
                student_loan_interest_deduction: student_loan_interest_deduction(applicant),
                tution_and_fees: tution_and_fees(applicant),
                other_magi_eligible_income: 0 #TODO
              }
            end

            def taxable_interest(applicant)
              applicant.incomes.where(kind: "interest").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def alimony(applicant)
              applicant.incomes.where(kind: "alimony_and_maintenance").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def capital_gain_or_loss(applicant)
              applicant.incomes.where(kind: "capital_gains").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def pensions_and_annuities_taxable_amount(applicant)
              applicant.incomes.where(kind: "pension_retirement_benefits").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def farm_income_or_loss(applicant)
              applicant.incomes.where(kind: "farming_and_fishing").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def unemployment_compensation(applicant)
              applicant.incomes.where(kind: "unemployment_income").inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def other_income(applicant)
              other_kinds = ["dividend", "rental_and_royalty", "social_security_benefit", "american_indian_and_alaskan_native",
                             "employer_funded_disability", "estate_trust", "foreign", "other", "prizes_and_awards"]
              applicant.incomes.where(:kind.in => other_kinds).inject(0) do |result, income|
                frequency = income.frequency_kind
                result += monthly_amount(frequency(frequency), income.amount.to_i)
                result
              end
            end

            def magi_deductions(applicant)
              other_kinds = ["alimony_paid", "domestic_production_activities", "penalty_on_early_withdrawal_of_savings",
                             "educator_expenses", "self_employment_sep_simple_and_qualified_plans", "self_employed_health_insurance",
                             "moving_expenses", "health_savings_account", "reservists_performing_artists_and_fee_basis_government_official_expenses"]
              applicant.deductions.where(:kind.in => other_kinds).inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += monthly_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def deductible_part_of_self_employment_tax(applicant)
              applicant.deductions.where(kind: "deductable_part_of_self_employment_taxes").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += monthly_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def ira_deduction(applicant)
              applicant.deductions.where(kind: "ira_deduction").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += monthly_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def student_loan_interest_deduction(applicant)
              applicant.deductions.where(kind: "student_loan_interest").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += monthly_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def tution_and_fees(applicant)
              applicant.deductions.where(kind: "tuition_and_fees").inject(0) do |result, deduction|
                frequency = deduction.frequency_kind
                result += monthly_amount(frequency(frequency), deduction.amount.to_i)
                result
              end
            end

            def annual_amount(frequency, amount)
              return 0 if frequency.blank? || amount.blank?

              case frequency
                when 'Weekly' then (amount * 52)
                when 'Monthly' then (amount * 12)
                when 'Annually' then amount
                when 'BiWeekly' then (amount * 26)
                when 'SemiMonthly' then (amount * 24)
                when 'Quarterly' then (amount * 4)
                when 'Hourly' then (amount * 8 * 5 * 52)
                when 'Daily' then (amount * 5 * 52)
                when 'SemiAnnually' then (amount * 2)
                when '13xPerYear' then (amount * 13)
                when '11xPerYear' then (amount * 11)
                when '10xPerYear' then (amount * 10)
                else 0
              end
            end

            def monthly_amount(frequency, amount)
              annual_amount(frequency, amount) / 12
            end

            # Was the applicant receiving coverage that has expired?
            # Any benefits of type is_enrolled and end dated.
            def had_prior_insurance?(applicant)
              applicant.benefits.any?{ |b| b.is_enrolled? && b.end_on.present? }
            end

            def vlp_document(applicant)
              return if applicant.vlp_subject.nil?
              {subject: applicant.vlp_subject,
               alien_number: applicant.alien_number,
               i94_number: applicant.i94_number,
               visa_number: applicant.visa_number,
               passport_number: applicant.passport_number,
               sevis_id: applicant.sevis_id,
               naturalization_number: applicant.naturalization_number,
               receipt_number: applicant.receipt_number,
               citizenship_number: applicant.citizenship_number,
               card_number: applicant.card_number,
               country_of_citizenship: applicant.country_of_citizenship,
               expiration_date: applicant.expiration_date.to_date,
               issuing_country: applicant.issuing_country,
               status: nil, # not sure what should be value here
               verification_type: nil, #not sure of value.
               comment: nil}
            end

            def addresses(applicant)
              applicant.addresses.inject([]) do |result, address|
                result << {kind: address.kind,
                           address_1: address.address_1,
                           address_2: address.address_2,
                           address_3: address.address_3,
                           city: address.city,
                           county: address.county,
                           state: address.state,
                           zip: address.zip,
                           country_name: address.country_name}
                result
              end
            end

            def emails(applicant)
              applicant.emails.inject([]) do |result, email|
                result << {kind: email.kind,
                           address: email.address}
                result
              end
            end

            def phones(applicant)
              applicant.phones.inject([]) do |result, phone|
                primary_phone = phone.primary.nil? ? false : phone.primary
                result << {kind: phone.kind,
                           primary: primary_phone,
                           area_code: phone.area_code,
                           number: phone.number,
                           country_code: phone.country_code,
                           extension: phone.extension,
                           full_phone_number: phone.full_phone_number}
                result
              end
            end

            def frequency(frequency)
              {"biweekly": "BiWeekly", "daily": "Daily", "half_yearly": "SemiAnnually",
               "monthly": "Monthly", "quarterly": "Quarterly", "weekly": "Weekly", "yearly": "Annually"}[frequency.to_sym]
            end

            def employer(instance)
              return if instance.employer_name.nil?
              {employer_name: instance.employer_name, employer_id: instance.employer_id}
            end

            def incomes(applicant)
              applicant.incomes.inject([]) do |result, income|
                result << { title: income.title,
                            kind: income.kind,
                            wage_type: income.wage_type,
                            hours_per_week: income.hours_per_week,
                            amount: income.amount.to_f,
                            amount_tax_exempt: income.amount_tax_exempt,
                            frequency_kind: frequency(income.frequency_kind),
                            start_on: income.start_on,
                            end_on: income.end_on,
                            is_projected: income.is_projected,
                            tax_form: income.tax_form,
                            employer: employer(income),
                            has_property_usage_rights: income.has_property_usage_rights,
                            submitted_at: income.submitted_at }
                result
              end
            end

            def benefits(applicant)
              applicant.benefits.inject([]) do |result, benefit|
                result << { name: benefit.title,
                            kind: benefit.insurance_kind,
                            status: benefit.kind,
                            is_employer_sponsored: benefit.is_employer_sponsored,
                            employer: employer(benefit),
                            esi_covered: benefit.esi_covered,
                            is_esi_waiting_period: benefit.is_esi_waiting_period,
                            is_esi_mec_met: benefit.is_esi_mec_met,
                            employee_cost: benefit.employee_cost,
                            employee_cost_frequency: benefit.employee_cost_frequency,
                            start_on: benefit.start_on,
                            end_on: benefit.end_on,
                            submitted_at: benefit.submitted_at,
                            hra_kind: benefit.hra_type }
                result
              end
            end

            def deductions(applicant)
              applicant.deductions.inject([]) do |result, deduction|
                result << { name: deduction.title,
                            kind: deduction.kind,
                            amount: deduction.amount.to_f,
                            start_on: deduction.start_on,
                            end_on: deduction.end_on,
                            frequency_kind: frequency(deduction.frequency_kind),
                            submitted_at: deduction.submitted_at}
                result
              end
            end

            def applicant_benchmark_premium(application)
              family = find_family(application.family_id) if application.family_id.present?
              return unless family.present?
              benchmark_premium = {:health_only_lcsp_premiums => [{member_identifier: "test", monthly_premium: BigDecimal(300)}],
                                   :health_only_slcsp_premiums => [{member_identifier: "test", monthly_premium: BigDecimal(300)}]}
              benchmark_premium #TODO: need to use operations from ivl_rating area for actual values.
            end

            def mitc_households(application)
              applicant_person_hbx_ids = application.applicants.map(&:person_hbx_id)
              people = applicant_person_hbx_ids.inject([]) do |result, id|
                result << {person_id: id}
              end
              [{household_id: application.hbx_id, people: people}]
            end

            def mitc_tax_returns(application)
              application.eligibility_determinations.inject([]) do |result, ed|
                result << mitc_return(ed)
                result
              end
            end

            def mitc_return(ed)
              ed_applicants = ed.applicants
              non_tax_dependents = ed_applicants.where(is_claimed_as_tax_dependent: false)
              tax_dependents = ed_applicants.where(is_claimed_as_tax_dependent: true)
              person_hbx_ids = non_tax_dependents.inject([]) do |hbx_ids, applicant|
                hbx_ids << {person_id: applicant.person_hbx_id}
              end
              dependent_hbx_ids = tax_dependents.where(is_primary_applicant: false).inject([]) do |hbx_ids, applicant|
                hbx_ids << {person_id: applicant.person_hbx_id}
              end
              {filers: person_hbx_ids, dependents: dependent_hbx_ids}
            end

            def tax_households(application)
              application.eligibility_determinations.inject([]) do |result, ed|
                result << {hbx_id: ed.hbx_assigned_id.to_s,
                           allocated_aptc: ed.max_aptc,
                           is_elibility_determined: ed.is_eligibility_determined,
                           start_date: ed.effective_starting_on,
                           end_date: ed.effective_ending_on,
                           tax_household_members: get_thh_member(ed, application),
                           eligibility_determinations: [max_aptc: ed.max_aptc,
                                                        csr_percent_as_integer: ed.csr_percent_as_integer,
                                                        determined_at: ed.determined_at]}
              end
            end

            def get_thh_member(ed, application)
              application.applicants.inject([]) do |result, app|
                result << {family_member_reference: {family_member_hbx_id: app.person_hbx_id.to_s,
                                                     first_name: app.first_name,
                                                     last_name: app.last_name,
                                                     person_hbx_id: app.person_hbx_id,
                                                     is_primary_family_member: app.is_primary_applicant},
                           product_eligibility_determination: {is_ia_eligible: app.is_ia_eligible?,
                                                               is_medicaid_chip_eligible: app.is_medicaid_chip_eligible,
                                                               is_non_magi_medicaid_eligible: app.is_non_magi_medicaid_eligible,
                                                               is_totally_ineligible: app.is_totally_ineligible,
                                                               is_without_assistance: app.is_without_assistance,
                                                               is_magi_medicaid: app.is_magi_medicaid,
                                                               magi_medicaid_monthly_household_income: app.magi_medicaid_monthly_household_income,
                                                               medicaid_household_size: app.medicaid_household_size,
                                                               magi_medicaid_monthly_income_limit: app.magi_medicaid_monthly_income_limit,
                                                               magi_as_percentage_of_fpl: app.magi_as_percentage_of_fpl,
                                                               magi_medicaid_category: app.magi_medicaid_category},
                           is_subscriber: app.is_primary_applicant,
                           reason: app.assisted_mec_reason} if app.eligibility_determination_id.to_s == ed.id.to_s
                result
              end
            end

            def application_relationships(application)
              relationships = application.relationships.inject([]) do |result, rl|
                applicant_id = rl.applicant_id
                relative_id = rl.relative_id
                return unless applicant_id.present? || relative_id.present?
                applicant = FinancialAssistance::Applicant.find(applicant_id)
                relative = FinancialAssistance::Applicant.find(relative_id)
                return unless applicant.present? || relative.present?
                result << {kind: kind,
                           applicant_reference: {first_name: applicant.first_name,
                                                 last_name: applicant.last_name,
                                                 dob: applicant.dob,
                                                 person_hbx_id: applicant.person_hbx_id,
                                                encrypted_ssn: applicant.encrypted_ssn },
                           relative_reference: {first_name: relative.first_name,
                                                last_name: relative.last_name,
                                                dob: relative.dob,
                                                person_hbx_id: relative.person_hbx_id,
                                                encrypted_ssn: relative.encrypted_ssn },
                            live_with_household_member: applicant.same_with_primary}
                result
              end
              relationships
            end

          end
        end
      end
    end
  end
end
