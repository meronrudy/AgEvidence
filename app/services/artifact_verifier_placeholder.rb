class ArtifactVerifierPlaceholder
  CONTRACT_VERSION = "verifier-result.v0"
  VERIFIER_NAME = "AgEvidence placeholder"
  VERIFIER_VERSION = "v0"

  def self.record!(artifact:, actor:, status: "pending_external_verifier", metadata: {})
    new(artifact: artifact, actor: actor, status: status, metadata: metadata).record!
  end

  def initialize(artifact:, actor:, status:, metadata:)
    @artifact = artifact
    @actor = actor
    @status = status
    @metadata = metadata
  end

  def record!
    result = VerifierResult.create!(
      organization: @artifact.organization,
      project: @artifact.project,
      artifact: @artifact,
      contract_version: CONTRACT_VERSION,
      verifier_name: VERIFIER_NAME,
      verifier_version: VERIFIER_VERSION,
      status: @status,
      artifact_digest: @artifact.digest,
      checked_at: Time.current,
      checks: [
        { "code" => "artifact_digest_recorded", "status" => "passed" },
        { "code" => "external_signature", "status" => "not_performed" }
      ],
      result: {
        "contract_version" => CONTRACT_VERSION,
        "status" => @status,
        "statement" => "AgEvidence recorded an internal consistency check placeholder. This is not independent third-party cryptographic verification."
      },
      metadata: @metadata
    )

    AuditEvent.log!(
      action: "verifier_result_recorded",
      actor: @actor,
      organization: @artifact.organization,
      auditable: result,
      metadata: @metadata.merge(artifact_code: @artifact.artifact_code, status: @status)
    )

    result
  end
end
