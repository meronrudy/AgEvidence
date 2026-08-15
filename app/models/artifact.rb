class Artifact < ApplicationRecord
  include JsonBacked

  belongs_to :project
  belongs_to :issued_by_user, class_name: "User", optional: true
  belongs_to :supersedes_artifact, class_name: "Artifact", optional: true
  has_many :superseding_artifacts, class_name: "Artifact", foreign_key: :supersedes_artifact_id, dependent: :nullify, inverse_of: :supersedes_artifact
  has_many :resource_grants, as: :grantable, dependent: :destroy
  has_many :statement_shares, dependent: :destroy
  has_many :verifier_results, dependent: :destroy
  has_many :reliance_events, dependent: :destroy

  json_field :artifact, default: {}
  json_field :integrity, :limitations, :receipt_chain, default: []

  before_update :prevent_issued_substance_mutation

  validates :artifact_code, :claim, :boundary, :jurisdiction, :program, :digest, :status, :contract_version, presence: true

  def organization
    project.organization
  end

  def issue!(issued_by: nil)
    update!(
      issued: true,
      issued_at: Time.current,
      issued_by_user: issued_by,
      status: "issued"
    )
  end

  def latest_verifier_result
    verifier_results.order(checked_at: :desc).first
  end

  def public_verification_payload
    verifier_result = latest_verifier_result

    {
      "contract_version" => "artifact-verification.v0",
      "artifact_code" => artifact_code,
      "status" => status,
      "digest" => digest,
      "claim" => claim,
      "boundary" => boundary,
      "program" => program,
      "profile_version" => artifact.dig("program", "version"),
      "issued_at" => issued_at&.utc&.iso8601,
      "limitations" => limitations.map { |item| item.slice("id", "code", "title", "statement", "detail") },
      "verifier_result" => verifier_result && {
        "status" => verifier_result.status,
        "verifier_name" => verifier_result.verifier_name,
        "verifier_version" => verifier_result.verifier_version,
        "checked_at" => verifier_result.checked_at.utc.iso8601
      }
    }
  end

  private

  def prevent_issued_substance_mutation
    return unless issued_was

    immutable_fields = %w[artifact_code claim boundary jurisdiction program digest artifact_json limitations_json receipt_chain_json contract_version]
    changed_immutable_fields = immutable_fields.select { |field| will_save_change_to_attribute?(field) }
    return if changed_immutable_fields.blank?

    errors.add(:base, "issued artifact substance is immutable: #{changed_immutable_fields.join(', ')}")
    throw(:abort)
  end
end
