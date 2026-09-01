module V1
  module Pricing
    class QuotesController < BaseController
      def create
        require_scope!("pricing:create")
        return if performed?
        require_product_capability!("pricing")
        return if performed?

        quote = ::Pricing::QuoteFactory.create!(
          organization: current_organization,
          attributes: quote_params
        )

        render json: serialize_quote(quote), status: :created
      end

      def show
        require_scope!("pricing:read")
        return if performed?
        require_product_capability!("pricing")
        return if performed?

        quote = find_quote(params[:id])
        render json: serialize_quote(quote)
      end

      private

      def quote_params
        source = params[:quote].presence || params
        ActionController::Parameters.new(source.to_unsafe_h).permit(
          :project_id,
          :project_code,
          :product_code,
          :pricing_unit,
          :currency,
          :quantity,
          :offered_price_cents,
          :offered_price,
          :discount_cents,
          :expires_at,
          scope: {},
          commercial_terms: {}
        )
      end

      def find_quote(identifier)
        if identifier.to_s.match?(/\A\d+\z/)
          current_organization.pricing_quotes.where(id: identifier).or(current_organization.pricing_quotes.where(quote_id: identifier)).first!
        else
          current_organization.pricing_quotes.find_by!(quote_id: identifier)
        end
      end

      def serialize_quote(quote)
        {
          quote_id: quote.quote_id,
          product_code: quote.product_code,
          product_version: quote.product_version,
          price_version_id: quote.price_version_id,
          pricing_experiment_id: quote.pricing_experiment_id,
          currency: quote.currency,
          amount: quote.amount_cents,
          list_price: quote.list_price_cents,
          offered_price: quote.offered_price_cents,
          discount: quote.discount_cents,
          pricing_unit: quote.pricing_unit,
          pricing_version: quote.pricing_version,
          quantity: quote.quantity,
          commercial_terms: quote.commercial_terms,
          breakdown: quote.breakdown,
          status: quote.status,
          expires_at: quote.expires_at&.iso8601,
          accepted_at: quote.accepted_at&.iso8601,
          notice: "Pricing is planning guidance until a quote is accepted."
        }
      end
    end
  end
end
