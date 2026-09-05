module EvidencePlane
  class VerifyStatement
    def self.call(statement:, actor: nil, metadata: {})
      Trust::Verifier.record_artifact!(
        artifact: statement,
        actor: actor,
        metadata: metadata
      )
    end
  end
end
