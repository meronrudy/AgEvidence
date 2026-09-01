module EvidencePlane
  class IssueStatement
    def self.call(statement:, actor:, metadata: {})
      ArtifactIssuanceService.issue!(artifact: statement, actor: actor, metadata: metadata)
    end
  end
end
