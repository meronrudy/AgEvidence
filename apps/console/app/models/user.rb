# app/models/user.rb
class User < ApplicationRecord
  DEMO_LOGIN_ALIAS = "demo"
  DEMO_LOGIN_EMAIL = "emma@agevidence.example"

  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
         :confirmable, :omniauthable, :trackable

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships
  has_many :invitations, foreign_key: :invited_by_user_id, class_name: 'Invitation', dependent: :destroy
  has_many :sent_invitations, foreign_key: :invited_by_user_id, class_name: 'Invitation', dependent: :nullify
  has_many :sessions, dependent: :destroy
  has_many :resource_grants, dependent: :destroy
  has_many :audit_events, foreign_key: :actor_id, class_name: 'AuditEvent', dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, :last_name, presence: true
  validates :provider, inclusion: { in: %w[email oidc google azure okta auth0] }
  validates :external_id, presence: true, if: -> { provider != "email" }

  def active_for_authentication?
    super && status == "active" && (primary_membership.present? || platform_role.present?)
  end

  def organization_id
    primary_membership&.organization_id
  end

  def primary_organization
    primary_membership&.organization
  end

  def primary_membership
    organization_memberships.active.includes(:organization, :role).order(:created_at).first
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def can_access_organization?(organization)
    organization_memberships.where(organization: organization, status: 'active').exists?
  end

  def has_role?(organization, role_name)
    organization_memberships.joins(:role).where(
      organization: organization,
      status: 'active',
      roles: { name: role_name.to_s }
    ).exists?
  end

  def platform_admin?
    platform_role == "platform_admin"
  end

  def support?
    platform_role == "support"
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if conditions[:email].to_s.downcase.strip == DEMO_LOGIN_ALIAS
      conditions[:email] = DEMO_LOGIN_EMAIL
    end

    super(conditions)
  end

  def self.from_omniauth(auth_hash)
    where(provider: auth_hash.provider, external_id: auth_hash.uid).first_or_create! do |user|
      name = auth_hash.info.name.to_s
      user.email = auth_hash.info.email
      user.first_name = auth_hash.info.first_name.presence || name.split.first || "AgEvidence"
      user.last_name = auth_hash.info.last_name.presence || name.split.drop(1).join(" ").presence || "User"
      user.password = Devise.friendly_token[0, 20]
      user.confirmed_at = Time.current
    end
  end
end
