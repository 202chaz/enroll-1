module AccessPolicies
  class EmployerProfile
    attr_accessor :user

    def initialize(user)
      @user = user
    end

    def authorize_show(employer, controller)
      return(true) if user.has_hbx_staff_role? || is_broker_for_employer?(employer.id)
      person = user.person

      if person.employer_staff_roles.length > 0
        ep_ids = user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s)
        if !ep_ids.include?(employer.id.to_s)
          controller.redirect_to_first_allowed
        end
        return true
      end
      controller.redirect_to_new
    end

    def authorize_index(broker_agency_id, controller)
      return(true) if user.has_hbx_staff_role?
      if user.has_broker_role? || user.has_broker_agency_staff_role?
        if !broker_agency_id.blank?
          return
        end
      end
      controller.redirect_to_new
    end

    def is_broker_for_employer?(employer_id)
      person = user.person
      return false unless person.broker_role || person.broker_agency_staff_roles.present?
      if person.broker_role
        employers = ::EmployerProfile.find_by_writing_agent(person.broker_role)
      else
        broker_agency_profiles = person.broker_agency_staff_roles.map {|role| ::BrokerAgencyProfile.find(role.broker_agency_profile_id) }
        employers = broker_agency_profiles.map { |bap| ::EmployerProfile.find_by_broker_agency_profile(bap) }.flatten
      end
      employers.map(&:id).map(&:to_s).include?(employer_id.to_s)
    end
  end
end
