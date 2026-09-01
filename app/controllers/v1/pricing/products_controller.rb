module V1
  module Pricing
    class ProductsController < BaseController
      def index
        require_scope!("pricing:read")
        return if performed?
        require_product_capability!("pricing")
        return if performed?

        products = current_product_pack.catalog.active.map do |product|
          price = PriceVersion.active
            .where(organization: current_organization, product_code: product.code)
            .order(effective_from: :desc, id: :desc)
            .first

          CommercialTelemetry::Recorder.record!(
            event_type: "product_viewed",
            organization: current_organization,
            product_code: product.code,
            value: {
              "organization_class" => "portfolio_company",
              "product_code" => product.code,
              "product_version" => product.product_version,
              "pricing_unit" => price&.pricing_unit || product.pricing_units.first,
              "currency" => price&.currency || product.currency
            }
          )

          serialize_product(product, price)
        end

        render json: {
          notice: "Pricing is planning guidance until a quote is accepted.",
          product_pack: {
            id: current_product_pack.id,
            version: current_product_pack.version,
            product_family: current_product_pack.product_family
          },
          products: products
        }
      end

      private

      def serialize_product(product, price)
        product.as_json.merge(
          price_version_id: price&.id,
          billing_type: product.pricing_model == "recurring" ? "recurring" : "one_time",
          base_planning_price_cents: price&.list_price_cents,
          minimum_price_cents: price&.minimum_price_cents,
          price_status: price&.status || "unpriced"
        )
      end
    end
  end
end
