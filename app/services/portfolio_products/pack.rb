module PortfolioProducts
  class Pack
    attr_reader :data, :brand, :navigation, :catalog, :telemetry_policy

    def initialize(data)
      @data = data
      @brand = Brand.new(data.fetch("branding", {}))
      @navigation = Navigation.new(data.fetch("navigation", []))
      @catalog = Catalog.new(data.fetch("products", []))
      @telemetry_policy = TelemetryPolicy.new(data.fetch("telemetry", {}))
    end

    def id
      data.fetch("id")
    end

    def company_code
      data.fetch("company_code")
    end

    def version
      data.fetch("version")
    end

    def display_name
      data.fetch("display_name")
    end

    def product_family
      data.fetch("product_family")
    end

    def deployment_mode
      data.fetch("deployment_mode", "shared_managed")
    end

    def workflows
      Array(data["workflows"])
    end

    def artifact_profiles
      Array(data["artifact_profiles"])
    end

    def program_profiles
      Array(data["program_profiles"])
    end

    def terminology
      data.fetch("terminology", {})
    end

    def feature_flags
      Array(data["feature_flags"])
    end

    def enabled?(capability)
      feature_flags.include?(capability.to_s)
    end

    def term(canonical)
      terminology.fetch(canonical.to_s, canonical.to_s)
    end

    def null?
      false
    end
  end
end
