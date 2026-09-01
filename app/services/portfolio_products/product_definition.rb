module PortfolioProducts
  class ProductDefinition
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def code
      data["code"]
    end

    def name
      data["name"]
    end

    def product_version
      data["product_version"]
    end

    def product_family
      data["product_family"]
    end

    def artifact_profile
      data["artifact_profile"]
    end

    def program_profiles
      Array(data["program_profiles"])
    end

    def pricing_unit
      data["pricing_unit"]
    end

    def pricing_units
      units = Array(data["pricing_units"])
      units = [pricing_unit] if units.empty? && pricing_unit.present?
      units
    end

    def pricing_model
      data["pricing_model"]
    end

    def currency
      data["currency"]
    end

    def active?
      data.fetch("active", true)
    end

    def quote_only?
      pricing_model == "quote_only"
    end

    def as_json(*)
      {
        code: code,
        name: name,
        product_version: product_version,
        product_family: product_family,
        artifact_profile: artifact_profile,
        program_profiles: program_profiles,
        pricing_units: pricing_units,
        pricing_model: pricing_model,
        currency: currency,
        active: active?
      }
    end
  end
end
