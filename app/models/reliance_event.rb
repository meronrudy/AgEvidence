class RelianceEvent < ApplicationRecord
  include JsonBacked

  RELIANCE_KINDS = %w[review procurement assurance attestation].freeze
  STATUSES = %w[recorded corrected superseded].freeze

  belongs_to :organization
  belongs_to :project
  belongs_to :artifact
  belongs_to :recorded_by_user, class_name: "User", optional: true

  json_field :basis, :metadata, default: {}

  before_validation :assign_event_code
  before_validation :assign_tenant_from_artifact

  validates :event_code, :relying_party, :relying_party_role, :reliance_kind, :status, :occurred_at, presence: true
  validates :event_code, uniqueness: true
  validates :reliance_kind, inclusion: { in: RELIANCE_KINDS }
  validates :status, inclusion: { in: STATUSES }
  validate :tenant_matches_artifact

  private

  def assign_event_code
    self.event_code = "REL-#{SecureRandom.hex(5).upcase}" if event_code.blank?
  end

  def assign_tenant_from_artifact
    self.project ||= artifact&.project
    self.organization ||= project&.organization
  end

  def tenant_matches_artifact
    return if artifact.blank? || project.blank? || organization.blank?
    return if artifact.project_id == project_id && project.organization_id == organization_id

    errors.add(:artifact, "must belong to the same project and organization")
  end
end
