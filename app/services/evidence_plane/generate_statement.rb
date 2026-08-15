module EvidencePlane
  class GenerateStatement
    def self.call(determination:, actor:, metadata: {})
      ArtifactAssemblyService.assemble!(determination: determination, actor: actor, metadata: metadata)
    end
  end
end
