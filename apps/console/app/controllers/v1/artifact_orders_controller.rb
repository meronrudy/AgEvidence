module V1
  class ArtifactOrdersController < BaseController
    def create
      require_scope!("artifact_orders:create")
      return if performed?
      require_product_capability!("artifact_orders")
      return if performed?

      quote = current_organization.pricing_quotes.find_by!(quote_id: order_params.fetch("quote_id"))
      product = current_product_pack.catalog.product!(quote.product_code)
      order = ArtifactOrder.create!(
        organization: current_organization,
        project: quote.project,
        pricing_quote: quote,
        product_code: quote.product_code,
        artifact_profile_code: product.artifact_profile,
        quantity: integer_or_nil(order_params["quantity"]) || quote.quantity,
        metadata: order_params["metadata"] || {}
      )

      CommercialTelemetry::Recorder.record!(
        event_type: "order_created",
        organization: current_organization,
        project: order.project,
        pricing_quote: quote,
        artifact_order: order,
        product_code: order.product_code,
        value: commercial_event_value(quote, order, "created")
      )

      render json: serialize_order(order), status: :created
    end

    def show
      require_scope!("artifact_orders:read")
      return if performed?
      require_product_capability!("artifact_orders")
      return if performed?

      order = find_order(params[:id])
      render json: serialize_order(order)
    end

    def checkout
      require_scope!("artifact_orders:create")
      return if performed?
      require_product_capability!("artifact_orders")
      return if performed?

      order = find_order(params[:id])
      order.checkout!
      order.pricing_quote&.accept!
      record_won_outcome!(order)

      CommercialTelemetry::Recorder.record!(
        event_type: "quote_accepted",
        organization: current_organization,
        project: order.project,
        pricing_quote: order.pricing_quote,
        artifact_order: order,
        product_code: order.product_code,
        value: commercial_event_value(order.pricing_quote, order, "won")
      )

      render json: serialize_order(order)
    end

    private

    def order_params
      source = params[:artifact_order].presence || params
      ActionController::Parameters.new(source.to_unsafe_h).permit(
        :quote_id,
        :quantity,
        metadata: {}
      )
    end

    def serialize_order(order)
      {
        order_id: order.order_id,
        quote_id: order.pricing_quote&.quote_id,
        product_code: order.product_code,
        artifact_profile_code: order.artifact_profile_code,
        quantity: order.quantity,
        status: order.status,
        checkout_completed_at: order.checkout_completed_at&.iso8601
      }
    end

    def find_order(identifier)
      if identifier.to_s.match?(/\A\d+\z/)
        current_organization.artifact_orders.where(id: identifier).or(current_organization.artifact_orders.where(order_id: identifier)).first!
      else
        current_organization.artifact_orders.find_by!(order_id: identifier)
      end
    end

    def commercial_event_value(quote, order, outcome)
      {
        "organization_class" => "portfolio_company",
        "product_code" => order.product_code,
        "product_version" => quote&.product_version,
        "pricing_unit" => quote&.pricing_unit,
        "currency" => quote&.currency,
        "list_price" => quote&.list_price_cents,
        "offered_price" => quote&.offered_price_cents,
        "accepted_price" => outcome == "won" ? quote&.offered_price_cents : nil,
        "quote_outcome" => outcome,
        "sales_cycle_days" => quote&.pricing_experiment&.metadata&.dig("sales_cycle_days"),
        "recurring_value" => quote&.pricing_experiment&.metadata&.dig("recurring_value_cents")
      }
    end

    def record_won_outcome!(order)
      quote = order.pricing_quote
      return unless quote

      CommercialOutcome.find_or_initialize_by(
        organization: current_organization,
        pricing_quote: quote,
        state: "won"
      ).tap do |outcome|
        outcome.artifact_order = order
        outcome.pricing_experiment = quote.pricing_experiment
        outcome.product_code = order.product_code
        outcome.occurred_at = Time.current
        outcome.sales_cycle_days = quote.pricing_experiment&.metadata&.dig("sales_cycle_days")
        outcome.accepted_price_cents = quote.offered_price_cents
        outcome.recurring_value_cents = quote.pricing_experiment&.metadata&.dig("recurring_value_cents")
        outcome.metadata = { "source" => "artifact_order_checkout" }
        outcome.save!
      end
    end

    def integer_or_nil(value)
      return if value.blank?

      Integer(value)
    end
  end
end
