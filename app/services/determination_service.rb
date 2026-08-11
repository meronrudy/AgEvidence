class DeterminationService
  def self.create!(program_profile:, project_name:, outcome:, adapter:, digest:, actor:, metadata: {})
    determination = Determination.create!(
      program_profile: program_profile,
      determination_code: "DET-#{SecureRandom.hex(4).upcase}",
      project_name: project_name,
      outcome: outcome,
      adapter: adapter,
      digest: digest,
      published_at: Time.current
    )

    AuditEvent.log!(
      action: "determination_created",
      actor: actor,
      organization: actor&.primary_organization,
      auditable: determination,
      metadata: metadata
    )

    determination
  end
end
