module CommercialTelemetry
  class Recorder
    def self.record!(event_type:, organization:, project: nil, pricing_quote: nil, artifact_order: nil, product_code: nil, value: {})
      policy = PortfolioProducts::Registry.fetch_for_organization(organization).telemetry_policy
      return unless policy.commercial_events?

      CommercialEvent.create!(
        organization: organization,
        project: project,
        pricing_quote: pricing_quote,
        artifact_order: artifact_order,
        product_code: product_code || pricing_quote&.product_code || artifact_order&.product_code,
        event_type: event_type,
        occurred_at: Time.current,
        value: policy.filter(value)
      )
    end
  end
end
