module HostedV1
  class PricingQuoteSerializer
    def initialize(quote)
      @quote = quote
    end

    def as_json
      {
        quote_id: @quote.quote_id,
        product_code: @quote.product_code,
        currency: @quote.currency,
        amount: @quote.amount_cents,
        pricing_version: @quote.pricing_version,
        breakdown: @quote.breakdown_json || [],
        status: @quote.status,
        expires_at: @quote.expires_at&.iso8601,
        accepted_at: @quote.accepted_at&.iso8601,
        notice: "Pricing is planning guidance until a quote is accepted."
      }
    end
  end
end