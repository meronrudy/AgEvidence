# app/models/concerns/organization_scoped.rb
module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    validates :organization_id, presence: true

    scope :for_organization, ->(organization) { where(organization: organization) }

    def self.accessible_by(user, organization = nil)
      return none unless user

      organization ||= user.primary_organization
      return none unless organization

      where(organization: organization)
    end
  end
end
