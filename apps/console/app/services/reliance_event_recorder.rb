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

      reliance_event
    end
  end
end
