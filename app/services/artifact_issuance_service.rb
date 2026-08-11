class ArtifactIssuanceService
  def self.issue!(artifact:, actor:, recipient: nil, access_level: "read", expires_in: 30.days, metadata: {})
    new(
      artifact: artifact,
      actor: actor,
      recipient: recipient,
      access_level: access_level,
      expires_in: expires_in,
      metadata: metadata
    ).issue!
  end

  def initialize(artifact:, actor:, recipient:, access_level:, expires_in:, metadata:)
    @artifact = artifact
    @actor = actor
    @recipient = recipient
    @access_level = access_level
    @expires_in = expires_in
    @metadata = metadata
  end

  def issue!
    Artifact.transaction do
      @artifact.issue!(issued_by: @actor)

      if @recipient
        ResourceGrant.grant_artifact_access(
          @recipient,
          @artifact,
          @actor,
          access_level: @access_level,
          expires_in: @expires_in
        )
      end

      AuditEvent.log!(
        action: "artifact_issued",
        actor: @actor,
        organization: @artifact.organization,
        auditable: @artifact,
        metadata: @metadata
      )

      @artifact
    end
  end
end
