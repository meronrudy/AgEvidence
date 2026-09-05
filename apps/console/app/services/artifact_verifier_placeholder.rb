class ArtifactVerifierPlaceholder
  def self.record!(artifact:, actor:, status: "pending_external_verifier", metadata: {})
    Trust::Verifier.record_artifact!(artifact: artifact, actor: actor, metadata: metadata.merge(legacy_requested_status: status))
  end
end
