# Broker-owned model to manage attributes of the prospective of existing employer
module SponsoredBenefits
  module Organizations
    class PlanDesignOrganization < Organization

      belongs_to :broker_agency_profile, class_name: "SponsoredBenefits::Organizations::BrokerAgencyProfile", inverse_of: :plan_design_organization

      # Plan design owner profile type & ID
      field :owner_profile_id,    type: BSON::ObjectId
      field :owner_profile_kind,  type: String, default: "::BrokerAgencyProfile"

      # Plan design owner role type & ID
      # field :owner_role_id, type: BSON::ObjectId
      # field :owner_role_kind,  type: String

      # Plan design customer profile type & ID
      field :customer_profile_id,         type: BSON::ObjectId
      field :customer_profile_class_name, type: String, default: "::EmployerProfile"
      field :entity_kind, type: String

      embeds_one :profile

      scope :find_by_profile,  ->(profile){ where(:"profile._id" => BSON::ObjectId.from_string(id)).first }

      def employer_profile
        ::EmployerProfile.find(customer_profile_id)
      end

      class << self
        def by_broker_agency_profile_id(id)
          SponsoredBenefits::Organizations::Organization.where('_type' => 'SponsoredBenefits::Organizations::PlanDesignOrganization')
        end
      end
    end
  end
end
