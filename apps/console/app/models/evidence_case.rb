# app/models/evidence_case.rb
class EvidenceCase < ApplicationRecord
  include OrganizationScoped

  belongs_to :organization
  belongs_to :project
  has_many :resource_grants, as: :grantable, dependent: :destroy

  validates :case_number, :slug, :status, presence: true
  validates :case_number, uniqueness: { scope: :organization_id }
  validates :slug, uniqueness: { scope: :organization_id }

  def can_be_accessed_by?(user)
    user.organization_memberships.where(organization: organization).exists? ||
      user.resource_grants.active.for_resource(self).exists?
  end
end
