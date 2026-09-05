class ArtifactAssemblyService
  CONTRACT_VERSION = "artifact-manifest.v0"

  def self.assemble!(determination:, actor:, artifact_profile: nil, metadata: {})
    new(determination: determination, actor: actor, artifact_profile: artifact_profile, metadata: metadata).assemble!
  end

  def initialize(determination:, actor:, artifact_profile:, metadata:)
    @determination = determination
    @project = determination.project
    @profile = determination.program_profile
    @evaluation = determination.evaluation
    @actor = actor
    @artifact_profile = artifact_profile
    @metadata = metadata
  end

  def assemble!
    Artifact.transaction do
      existing = @project.artifact
      artifact = existing&.issued? ? nil : existing
      artifact ||= @project.artifacts.build(artifact_code: "RA-#{SecureRandom.hex(5).upcase}")
      manifest = build_manifest(artifact.artifact_code)
      digest = ApplicationDigest.sha256(manifest)
      manifest["digest"] = digest
      artifact.assign_attributes(
        claim: @determination.outcome,
        boundary: "#{@project.name} / #{@project.scope}",
        jurisdiction: @project.jurisdiction,
        program: "#{@profile.program} #{@profile.profile_version}",
        digest: digest,
        status: "ready",
        issued: false,
        contract_version: CONTRACT_VERSION,
        supersedes_artifact: existing&.issued? ? existing : nil,
        artifact: manifest,
        integrity: integrity_checks(digest),
        limitations: manifest.fetch("limitations"),
        receipt_chain: manifest.fetch("receipt_chain")
      )
      artifact.save!

      AuditEvent.log!(
        action: "artifact_assembled",
        actor: @actor,
        organization: @project.organization,
        auditable: artifact,
        metadata: @metadata.merge(artifact_code: artifact.artifact_code, digest: digest)
      )

      artifact
    end
  end

  private

  def build_manifest(artifact_code)
    {
      "contract_version" => CONTRACT_VERSION,
      "canonicalization" => "Rails StableJson object keys sorted recursively before app:sha256 digest; not a receipt commitment or cross-runtime verifier claim.",
      "artifact_code" => artifact_code,
      "project" => {
        "project_code" => @project.project_code,
        "name" => @project.name,
        "jurisdiction" => @project.jurisdiction,
        "program" => @project.program,
        "scope" => @project.scope
      },
      "determination" => {
        "determination_code" => @determination.determination_code,
        "outcome" => @determination.outcome,
        "digest" => @determination.digest
      },
      "evaluation" => {
        "evaluation_code" => @evaluation&.evaluation_code,
        "input_digest" => @evaluation&.input_digest,
        "profile_version" => @evaluation&.profile_version
      },
      "profile" => {
        "code" => @profile.code,
        "version" => @profile.profile_version,
        "requirements_digest" => @profile.requirements_digest
      },
      "artifact_profile" => {
        "code" => @artifact_profile&.profile_code || @profile.artifact_profile_selection || "default",
        "version" => @artifact_profile&.profile_version || "v0"
      },
      "source_records" => @project.source_records.order(:record_code).map(&:public_bundle_payload),
      "evidence_records" => @project.evidence_records.order(:record_code).map do |record|
        {
          "record_code" => record.record_code,
          "source_record_code" => record.source_record&.record_code,
          "schema_name" => record.schema_name,
          "digest" => record.digest,
          "status" => record.status
        }
      end,
      "limitations" => determination_limitations,
      "receipt_chain" => [
        { "label" => "Evaluation", "digest" => @evaluation&.input_digest },
        { "label" => "Determination", "digest" => @determination.digest }
      ]
    }
  end

  def determination_limitations
    limitations = @determination.result.fetch("limitations", [])
    limitations.map.with_index(1) do |item, index|
      {
        "code" => item["code"] || item[:code] || "LIM-#{index.to_s.rjust(2, '0')}",
        "statement" => item["statement"] || item[:statement] || item["detail"] || item[:detail],
        "basis" => item["basis"] || item[:basis] || @determination.determination_code
      }
    end
  end

  def integrity_checks(digest)
    [
      { "label" => "Application digest computed", "ok" => true, "digest" => digest },
      { "label" => "Profile version recorded", "ok" => @profile.profile_version.present? },
      { "label" => "External verifier", "ok" => false, "status" => "pending_external_verifier" }
    ]
  end
end
