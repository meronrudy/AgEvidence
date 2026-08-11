# app/models/resource_grant.rb
class ResourceGrant < ApplicationRecord
  belongs_to :user
  belongs_to :grantable, polymorphic: true
  belongs_to :granted_by_user, class_name: 'User', optional: true

  validates :user_id, :grantable_type, :grantable_id, presence: true
  validates :access_level, inclusion: { in: %w[read write admin] }
  validates :expires_at, presence: true

  scope :active, -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }
  scope :for_artifact, -> { where(grantable_type: 'Artifact') }
  scope :for_evidence_record, -> { where(grantable_type: 'EvidenceRecord') }
  scope :for_evidence_case, -> { where(grantable_type: 'EvidenceCase') }
  scope :for_resource, ->(resource) { where(grantable: resource) }

  def expired?
    expires_at <= Time.current
  end

  def revoke!
    update!(expires_at: Time.current, revoked_at: Time.current)
  end

  def self.grant_artifact_access(user, artifact, granted_by, expires_in: 30.days, access_level: 'read')
    create!(
      user: user,
      grantable: artifact,
      granted_by_user: granted_by,
      access_level: access_level,
      expires_at: expires_in.from_now
    )
  end

  def self.grant_evidence_case_access(user, evidence_case, granted_by, expires_in: 30.days, access_level: 'read')
    create!(
      user: user,
      grantable: evidence_case,
      granted_by_user: granted_by,
      access_level: access_level,
      expires_at: expires_in.from_now
    )
  end
end
