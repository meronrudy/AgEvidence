# app/models/invitation.rb
class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by_user, class_name: 'User', optional: true
  belongs_to :role, class_name: 'Role'

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :status, inclusion: { in: %w[pending accepted expired revoked] }

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  scope :pending, -> { where(status: 'pending').where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def accept!(user)
    transaction do
      update!(status: 'accepted', accepted_at: Time.current)
      OrganizationMembership.find_or_create_by!(
        user: user,
        organization: organization
      ) do |membership|
        membership.role = role
        membership.status = 'active'
        membership.joined_at = Time.current
      end.tap do |membership|
        membership.update!(role: role, status: 'active', joined_at: Time.current)
      end
    end
  end

  def pending?
    status == "pending" && !expired?
  end

  def revoked?
    status == "revoked"
  end

  def expired?
    expires_at <= Time.current || status == "expired"
  end

  def revoke!
    update!(status: 'revoked')
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end
end
