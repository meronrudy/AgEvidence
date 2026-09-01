module Pricing
  class QuoteFactory
    def self.create!(organization:, attributes:)
      new(organization: organization, attributes: attributes.to_h).create!
    end

    def initialize(organization:, attributes:)
      @organization = organization
      @attributes = attributes.deep_stringify_keys
      @pack = PortfolioProducts::Registry.fetch_for_organization(organization)
    end

    def create!
      raise ArgumentError, "pricing is not enabled for this product pack" unless @pack.enabled?("pricing")

      product = @pack.catalog.product!(@attributes.fetch("product_code"))
      raise ArgumentError, "product is inactive" unless product.active?

      pricing_unit = @attributes["pricing_unit"].presence || product.pricing_units.first
      currency = @attributes["currency"].presence || product.currency || @organization.default_currency
      price_version = active_price_version!(product: product, pricing_unit: pricing_unit, currency: currency)
      offered_price_cents = integer_or_nil(@attributes["offered_price_cents"]) || integer_or_nil(@attributes["offered_price"])

      if price_version.quote_only? && offered_price_cents.blank?
        raise ArgumentError, "#{product.code} is quote-only and requires offered_price_cents"
      end

      project = resolve_project
      experiment = active_experiment(product: product, price_version: price_version)
      quote = PricingQuote.create!(
        organization: @organization,
        project: project,
        price_version: price_version,
        pricing_experiment: experiment,
        product_code: product.code,
        product_version: product.product_version,
        currency: currency,
        pricing_unit: pricing_unit,
        list_price_cents: price_version.list_price_cents,
        offered_price_cents: offered_price_cents || price_version.list_price_cents,
        discount_cents: integer_or_nil(@attributes["discount_cents"]),
        quantity: integer_or_nil(@attributes["quantity"]) || 1,
        commercial_terms: commercial_terms,
        breakdown: quote_breakdown(product: product, price_version: price_version),
        status: "quoted",
        expires_at: expires_at
      )

      CommercialTelemetry::Recorder.record!(
        event_type: "quote_created",
        organization: @organization,
        project: project,
        pricing_quote: quote,
        product_code: quote.product_code,
        value: telemetry_value(quote, product, "quoted")
      )

      quote
    end

    private

    def active_price_version!(product:, pricing_unit:, currency:)
      PriceVersion.active
        .where(
          organization: @organization,
          product_code: product.code,
          product_version: product.product_version,
          currency: currency,
          pricing_unit: pricing_unit
        )
        .order(effective_from: :desc, id: :desc)
        .first || raise(ActiveRecord::RecordNotFound, "no active price version for #{product.code}")
    end

    def resolve_project
      project_code = @attributes["project_id"].presence || @attributes["project_code"].presence
      return if project_code.blank?

      @organization.projects.find_by!("project_code = ? OR slug = ?", project_code, project_code)
    end

    def active_experiment(product:, price_version:)
      @organization.pricing_experiments
        .where(
          product_code: product.code,
          product_version: product.product_version,
          pricing_unit: price_version.pricing_unit,
          status: "active"
        )
        .where(price_version_id: [price_version.id, nil])
        .order(started_at: :desc, id: :desc)
        .first
    end

    def commercial_terms
      terms = @attributes["commercial_terms"] || @attributes["scope"] || {}
      terms.is_a?(Hash) ? terms : {}
    end

    def expires_at
      raw = @attributes["expires_at"].presence
      raw ? Time.zone.parse(raw) : 30.days.from_now
    end

    def quote_breakdown(product:, price_version:)
      [
        {
          "label" => product.name,
          "product_code" => product.code,
          "price_version_id" => price_version.id,
          "pricing_unit" => price_version.pricing_unit,
          "list_price_cents" => price_version.list_price_cents
        }
      ]
    end

    def telemetry_value(quote, product, outcome)
      {
        "organization_class" => "portfolio_company",
        "product_code" => quote.product_code,
        "product_version" => quote.product_version,
        "customer_segment" => quote.pricing_experiment&.customer_segment,
        "geography" => quote.pricing_experiment&.geography,
        "pricing_unit" => quote.pricing_unit,
        "currency" => quote.currency,
        "list_price" => quote.list_price_cents,
        "offered_price" => quote.offered_price_cents,
        "accepted_price" => nil,
        "quote_outcome" => outcome,
        "source_records_ingested" => quote.project&.source_records&.count,
        "evidence_records_generated" => quote.project&.evidence_records&.count,
        "model_or_evaluation_runs" => (quote.project&.model_runs&.count || 0) + (quote.project&.evaluations&.count || 0),
        "artifacts_generated" => quote.project&.artifacts&.count,
        "reviewer_actions" => quote.project&.reviews&.joins(:review_decisions)&.count,
        "reviewer_minutes" => quote.pricing_experiment&.metadata&.dig("workload", "reviewer_minutes"),
        "support_minutes" => quote.pricing_experiment&.metadata&.dig("workload", "support_minutes"),
        "api_requests" => ApiLog.where(organization: @organization).count,
        "exports_or_external_recipients" => quote.project&.artifact&.statement_shares&.count,
        "reliance_events" => quote.project&.reliance_events&.count,
        "recurring_value" => quote.pricing_experiment&.metadata&.dig("recurring_value_cents"),
        "product_name" => product.name
      }
    end

    def integer_or_nil(value)
      return if value.blank?

      Integer(value)
    end
  end
end
