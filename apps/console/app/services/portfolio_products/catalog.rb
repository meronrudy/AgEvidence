module PortfolioProducts
  class Catalog
    attr_reader :products

    def initialize(products = [])
      @products = Array(products).map { |attrs| ProductDefinition.new(attrs) }
    end

    def active
      products.select(&:active?)
    end

    def product(code)
      products.find { |product| product.code == code.to_s }
    end

    def product!(code)
      product(code) || raise(KeyError, "unknown product code #{code}")
    end

    def codes
      products.map(&:code)
    end
  end
end
