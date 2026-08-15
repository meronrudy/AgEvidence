class ModelRunRecordingService
  def self.create!(project:, actor:, attributes:, candidates: [], metadata: {})
    new(project: project, actor: actor, attributes: attributes, candidates: candidates, metadata: metadata).create!
  end

  def initialize(project:, actor:, attributes:, candidates:, metadata:)
    @project = project
    @actor = actor
    @attributes = attributes.to_h
    @candidates = candidates || []
    @metadata = metadata
  end

  def create!
    ModelRun.transaction do
      model_run = @project.model_runs.create!(
        @attributes.merge(
          organization: @project.organization,
          started_at: @attributes[:started_at] || @attributes["started_at"] || Time.current
        )
      )

      if model_run.status == "completed"
        @candidates.each do |candidate|
          attrs = candidate.to_h
          model_run.evidence_candidates.create!(
            evidence_record: attrs[:evidence_record] || attrs["evidence_record"],
            candidate_type: attrs[:candidate_type] || attrs["candidate_type"],
            claim: attrs[:claim] || attrs["claim"],
            confidence: attrs[:confidence] || attrs["confidence"],
            status: attrs[:status] || attrs["status"] || "review_required",
            basis: attrs[:basis] || attrs["basis"] || [],
            limitations: attrs[:limitations] || attrs["limitations"] || []
          )
        end
      end

      AuditEvent.log!(
        action: "model_run_recorded",
        actor: @actor,
        organization: @project.organization,
        auditable: model_run,
        metadata: @metadata.merge(run_code: model_run.run_code, adapter_name: model_run.adapter_name, status: model_run.status)
      )

      model_run
    end
  end
end
