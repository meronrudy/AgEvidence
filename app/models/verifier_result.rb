class VerifierResult < ApplicationRecord
  include JsonBacked

  STATUSES = %w[pending_external_verifier locally_consistent failed superseded].freeze

  belongs_to :organization
  belongs_to :project
  belongs_to :artifact

  json_field :checks, default: []
  json_field :result, :metadata, default: {}

  before_validation :assign_result_code
  before_validation :assign_tenant_from_artifact

  validates :result_code, :contract_version, :verifier_name, :verifier_version,
            :status, :artifact_digest, :checked_at, presence: true
  validates :result_code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validate :tenant_matches_artifact

  private

  def assign_result_code
    self.result_code = "VR-#{SecureRandom.hex(5).upcase}" if result_code.blank?
  end

  def assign_tenant_from_artifact
    self.project ||= artifact&.project
    self.organization ||= project&.organization
    self.artifact_digest ||= artifact&.digest
  end

  def tenant_matches_artifact
    return if artifact.blank? || project.blank? || organization.blank?
    return if artifact.project_id == project_id && project.organization_id == organization_id

    errors.add(:artifact, "must belong to the same project and organization")
  end
end
