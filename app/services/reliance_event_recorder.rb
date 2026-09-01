class RelianceEventRecorder
  def self.record!(artifact:, actor:, attributes:, metadata: {})
    new(artifact: artifact, actor: actor, attributes: attributes, metadata: metadata).record!
  end

  def initialize(artifact:, actor:, attributes:, metadata:)
    @artifact = artifact
    @actor = actor
    @attributes = attributes.to_h
    @metadata = metadata
  end

  def record!
    RelianceEvent.transaction do
      reliance_event = @artifact.reliance_events.create!(
        @attributes.merge(
          organization: @artifact.organization,
          project: @artifact.project,
          recorded_by_user: @actor,
          status: @attributes[:status] || @attributes["status"] || "recorded",
          occurred_at: @attributes[:occurred_at] || @attributes["occurred_at"] || Time.current
        )
      )

      AuditEvent.log!(
        action: "reliance_event_recorded",
        actor: @actor,
        organization: @artifact.organization,
        auditable: reliance_event,
        metadata: @metadata.merge(artifact_code: @artifact.artifact_code, event_code: reliance_event.event_code)
      )

      CommercialTelemetry::Recorder.record!(
        event_type: "reliance_recorded",
        organization: @artifact.organization,
        project: @artifact.project,
        product_code: product_code,
        value: {
          "organization_class" => "portfolio_company",
          "product_code" => product_code,
          "artifacts_generated" => @artifact.project.artifacts.count,
          "source_records_ingested" => @artifact.project.source_records.count,
          "evidence_records_generated" => @artifact.project.evidence_records.count,
          "model_or_evaluation_runs" => @artifact.project.model_runs.count + @artifact.project.evaluations.count,
          "reviewer_actions" => @artifact.project.reviews.joins(:review_decisions).count,
          "reliance_events" => @artifact.project.reliance_events.count
        }
      )

      reliance_event
    end
  end

  def product_code
    @metadata[:product_code] ||
      @metadata["product_code"] ||
      @artifact.artifact["portfolio_product_code"] ||
      @artifact.project.metadata["product_code"]
  end
end
