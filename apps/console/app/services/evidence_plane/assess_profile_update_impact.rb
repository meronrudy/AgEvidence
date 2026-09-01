module EvidencePlane
  class AssessProfileUpdateImpact
    def self.call(profile:)
      profile.version_impact
    end
  end
end
