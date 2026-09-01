module PortfolioProducts
  class Brand
    attr_reader :data

    def initialize(data = {})
      @data = data || {}
    end

    def product_name
      data.fetch("product_name", "AgEvidence")
    end

    def company_name
      data.fetch("company_name", "AgEvidence")
    end

    def accent_token
      data.fetch("accent_token", "default")
    end

    def logo
      data["logo"]
    end

    def favicon
      data["favicon"]
    end

    def footer
      data.fetch("footer", {})
    end

    def support
      data.fetch("support", {})
    end

    def attribution
      data.fetch("attribution", "powered_by_agevidence")
    end

    def attribution_label
      case attribution
      when "powered_by_agevidence"
        "Powered by AgEvidence"
      when "infrastructure_by_agevidence"
        "Evidence infrastructure by AgEvidence"
      when "none"
        nil
      else
        "Powered by AgEvidence"
      end
    end
  end
end
