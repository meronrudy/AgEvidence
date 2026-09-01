module PortfolioProducts
  class NullPack < Pack
    def initialize
      super(
        "id" => "agevidence.default",
        "company_code" => "agevidence",
        "version" => "0.0.0",
        "display_name" => "AgEvidence",
        "product_family" => "AgEvidence Evidence Plane",
        "deployment_mode" => "shared_managed",
        "workflows" => [],
        "artifact_profiles" => [],
        "program_profiles" => [],
        "terminology" => {
          "Artifact" => "Evidence Statement",
          "Artifacts" => "Evidence Statements"
        },
        "feature_flags" => Registry::KNOWN_FEATURE_FLAGS,
        "branding" => {
          "product_name" => "AgEvidence",
          "company_name" => "AgEvidence",
          "attribution" => "none"
        },
        "navigation" => Registry.default_navigation,
        "products" => [],
        "telemetry" => {}
      )
    end

    def null?
      true
    end
  end
end
