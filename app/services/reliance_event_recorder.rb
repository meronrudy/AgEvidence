class RelianceEventRecorder
  def self.record!(artifact:, actor:, attributes:, metadata: {})
    puts "DEBUG: RelianceEventRecorder.record! called with artifact=#{artifact.artifact_code}, actor=#{actor.inspect}"
    result = new(artifact: artifact, actor: actor, attributes: attributes, metadata: metadata).record!
    puts "DEBUG: RelianceEventRecorder.record! finished, result=#{result.inspect}"
    result
  end

  def initialize(artifact:, actor:, attributes:, metadata:)
    @artifact = artifact
    @actor = actor
    @attributes = attributes.to_h
    @metadata = metadata
  end

  def record!
    puts "DEBUG: Creating reliance event with attributes: #{@attributes.inspect}"
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
      puts "DEBUG: Created reliance event: #{reliance_event.inspect}"

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
