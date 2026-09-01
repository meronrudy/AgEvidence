class DeterminationService
  def self.create!(program_profile:, project:, outcome:, adapter:, digest:, actor:, evaluation: nil, project_name: nil, metadata: {})
    determination = Determination.create!(
      program_profile: program_profile,
      project: project,
      evaluation: evaluation,
      determination_code: "DET-#{SecureRandom.hex(4).upcase}",
      project_name: project_name.presence || project.name,
      outcome: outcome,
      adapter: adapter,
      digest: digest,
      published_at: Time.current,
      status: "published",
      result: {
        "contract_version" => "determination-result.v0",
        "profile_version" => program_profile.profile_version,
        "limitations" => []
      }
    )

    AuditEvent.log!(
      action: "determination_created",
      actor: actor,
      organization: project.organization,
      auditable: determination,
      metadata: metadata
    )

    determination
  end
end
