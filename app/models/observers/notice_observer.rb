module Observers
  class NoticeObserver < Observer

    def plan_year_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if PlanYear::REGISTERED_EVENTS.include?(new_model_event.event_key)
        plan_year = new_model_event.klass_instance

        if new_model_event.event_key == :renewal_application_denied
          errors = plan_year.enrollment_errors

          if(errors.include?(:eligible_to_enroll_count) || errors.include?(:non_business_owner_enrollment_count))
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_ineligibility_notice")

            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "employee_renewal_employer_ineligibility_notice")
              end
            end
          end
        end

        if new_model_event.event_key == :renewal_employer_open_enrollment_completed
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_employer_open_enrollment_completed")
        end

        if new_model_event.event_key == :renewal_application_submitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_published")
        end

        if new_model_event.event_key == :renewal_application_created
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "renewal_application_created")
        end

        if new_model_event.event_key == :renewal_application_autosubmitted
          trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "plan_year_auto_published")
        end

        if new_model_event.event_key == :ineligible_renewal_application_submitted

          if plan_year.application_eligibility_warnings.include?(:primary_office_location)
            trigger_notice(recipient: plan_year.employer_profile, event_object: plan_year, notice_event: "employer_renewal_eligibility_denial_notice")
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              if ce.employee_role.present?
                trigger_notice(recipient: ce.employee_role, event_object: plan_year, notice_event: "termination_of_employers_health_coverage")
              end
            end
          end
        end

        if new_model_event.event_key == :renewal_enrollment_confirmation
          trigger_notice(recipient: plan_year.employer_profile,  event_object: plan_year, notice_event: "renewal_employer_open_enrollment_completed" )
            plan_year.employer_profile.census_employees.non_terminated.each do |ce|
              enrollments = ce.renewal_benefit_group_assignment.hbx_enrollments
              enrollment = enrollments.select{ |enr| (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES).include?(enr.aasm_state) }.sort_by(&:updated_at).last
              if enrollment.present?
                trigger_notice(recipient: ce.employee_role, event_object: enrollment, notice_event: "renewal_employee_enrollment_confirmation")
              end
            end
        end

        if PlanYear::DATA_CHANGE_EVENTS.include?(new_model_event.event_key)
        end
      end
    end

    def employer_profile_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)
      if EmployerProfile::REGISTERED_EVENTS.include?(new_model_event.event_key)
        employer_profile = new_model_event.klass_instance
        if new_model_event.event_key == :generate_initial_employer_invoice
          if employer_profile.is_new_employer?
            trigger_notice(recipient: employer_profile, event_object: employer_profile.plan_years.where(:aasm_state.in => PlanYear::INITIAL_ELIGIBLE_STATE).first, notice_event: "generate_initial_employer_invoice")
          end
        end
      end
    end

    def hbx_enrollment_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if HbxEnrollment::REGISTERED_EVENTS.include?(new_model_event.event_key)
        hbx_enrollment = new_model_event.klass_instance
        if new_model_event.event_key == :application_coverage_selected
          if hbx_enrollment.is_shop?
            if (hbx_enrollment.enrollment_kind == "special_enrollment" || hbx_enrollment.census_employee.new_hire_enrollment_period.cover?(TimeKeeper.date_of_record))
              trigger_notice(recipient: hbx_enrollment.census_employee.employee_role, event_object: hbx_enrollment, notice_event: "employee_plan_selection_confirmation_sep_new_hire")
            end
          end
        end
      end
    end

    def plan_year_date_change(model_event)
      current_date = TimeKeeper.date_of_record
      if PlanYear::DATA_CHANGE_EVENTS.include?(model_event.event_key)
        if model_event.event_key == :renewal_employer_publish_plan_year_reminder_after_soft_dead_line
          trigger_on_queried_records("renewal_employer_publish_plan_year_reminder_after_soft_dead_line")
        end

        if model_event.event_key == :renewal_plan_year_first_reminder_before_soft_dead_line
          trigger_on_queried_records("renewal_plan_year_first_reminder_before_soft_dead_line")
        end

        if model_event.event_key == :renewal_plan_year_publish_dead_line
          trigger_on_queried_records("renewal_plan_year_publish_dead_line")
        end

      end
    end

    def employer_profile_date_change; end
    def hbx_enrollment_date_change; end
    def census_employee_date_change; end

    def census_employee_update(new_model_event)
      raise ArgumentError.new("expected ModelEvents::ModelEvent") unless new_model_event.is_a?(ModelEvents::ModelEvent)

      if  CensusEmployee::REGISTERED_EVENTS.include?(new_model_event.event_key)
        census_employee = new_model_event.klass_instance
        trigger_notice(recipient: census_employee.employee_role, event_object: new_model_event.options[:event_object], notice_event: new_model_event.event_key.to_s)
      end
    end

    def trigger_on_queried_records(event_name)
      current_date = TimeKeeper.date_of_record
      organizations_for_force_publish(current_date).each do |organization|
        plan_year = organization.employer_profile.plan_years.where(:aasm_state => 'renewing_draft').first
        trigger_notice(recipient: organization.employer_profile, event_object: plan_year, notice_event:event_name)
      end
    end
  end
end
