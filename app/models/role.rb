# app/models/role.rb
class Role < ApplicationRecord
  NAMES = %w[
    org_admin
    operator
    reviewer
    approver
    viewer
    auditor
    platform_admin
    support
  ].freeze

  enum :name, {
    org_admin: 'org_admin',
    operator: 'operator',
    reviewer: 'reviewer',
    approver: 'approver',
    viewer: 'viewer',
    auditor: 'auditor',
    platform_admin: 'platform_admin',
    support: 'support'
  }

  belongs_to :organization
  has_many :organization_memberships, dependent: :destroy

  validates :name, presence: true, inclusion: { in: NAMES }, uniqueness: { scope: :organization_id }

  def self.default_roles_for_organization(organization)
    NAMES.each do |role_name|
      find_or_create_by!(organization: organization, name: role_name)
    end
  end

  def can_manage_organization?
    org_admin? || platform_admin?
  end

  def can_manage_evidence?
    org_admin? || operator? || reviewer? || approver?
  end

  def can_manage_artifacts?
    org_admin? || operator?
  end

  def can_view_audit_logs?
    org_admin? || auditor? || platform_admin?
  end
end
