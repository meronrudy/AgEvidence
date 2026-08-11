# app/models/organization_membership.rb
class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :role, class_name: 'Role'

  validates :user_id, uniqueness: { scope: :organization_id }
  validates :organization_id, :role_id, :status, presence: true
  validate :role_belongs_to_organization

  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }

  def activate!
    update!(status: 'active', joined_at: Time.current)
  end

  def deactivate!
    update!(status: 'inactive')
  end

  private

  def role_belongs_to_organization
    return unless role && organization

    errors.add(:role, "must belong to the membership organization") if role.organization_id != organization_id
  end
end
