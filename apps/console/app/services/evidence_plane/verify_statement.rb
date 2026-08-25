module EvidencePlane
  class VerifyStatement
    def self.call(statement:, actor: nil, metadata: {})
      ArtifactVerifierPlaceholder.record!(
        artifact: statement,
        actor: actor,
        status: "locally_consistent",
        metadata: metadata
      )
    end
  end
end
