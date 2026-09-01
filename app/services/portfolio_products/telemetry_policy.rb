module PortfolioProducts
  class TelemetryPolicy
    DEFAULT_DENY = %w[
      customer_identity
      raw_evidence_payloads
      proprietary_model_parameters
      contract_text
      confidential_geometries
    ].freeze

    attr_reader :data

    def initialize(data = {})
      @data = data || {}
    end

    def commercial_events?
      data.fetch("commercial_events", false)
    end

    def workload_metrics?
      data.fetch("workload_metrics", false)
    end

    def include_fields
      Array(data["include"])
    end

    def excluded_fields
      (DEFAULT_DENY + Array(data["exclude"])).uniq
    end

    def filter(value)
      source = (value || {}).deep_stringify_keys
      allowed = include_fields.presence || source.keys
      source.slice(*allowed).except(*excluded_fields)
    end
  end
end
