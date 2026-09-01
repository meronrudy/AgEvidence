require "test_helper"

class PortfolioPricingTest < ActionDispatch::IntegrationTest
  EARTHODIC_TOKEN = "earthodic_demo_2026"
  DIT_TOKEN = "agev_live_demo_7f91"

  setup do
    seed_demo!
    @earthodic = Organization.find_by!(name: "Earthodic Demo")
    @dit = Organization.find_by!(name: "DIT AgTech")
  end

  test "pricing products resolve from the current organization product pack" do
    get "/v1/pricing/products", headers: api_headers(EARTHODIC_TOKEN)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "earthodic.biobarc_qualification", body.dig("product_pack", "id")
    assert_equal "1.0.0", body.dig("product_pack", "version")
    assert_equal PortfolioProducts::Registry.fetch("earthodic").catalog.codes.sort,
      body.fetch("products").map { |product| product.fetch("code") }.sort

    get "/v1/pricing/products", headers: api_headers(DIT_TOKEN)

    assert_response :success
    assert_empty JSON.parse(response.body).fetch("products")
  end

  test "application qualification quote binds exact price version and experiment" do
    price = @earthodic.price_versions.find_by!(
      product_code: "application_qualification",
      product_version: "1.2",
      currency: "AUD",
      pricing_unit: "application"
    )
    experiment = @earthodic.pricing_experiments.find_by!(product_code: "application_qualification")

    assert_difference -> { @earthodic.pricing_quotes.count }, 1 do
      assert_difference -> { @earthodic.commercial_events.where(event_type: "quote_created").count }, 1 do
        post "/v1/pricing/quotes",
          params: {
            quote: {
              product_code: "application_qualification",
              project_code: "PRJ-EARTH-APP-001",
              pricing_unit: "application",
              currency: "AUD",
              offered_price_cents: 1_900_000
            }
          }.to_json,
          headers: api_headers(EARTHODIC_TOKEN)
      end
    end

    assert_response :created
    body = JSON.parse(response.body)
    quote = @earthodic.pricing_quotes.find_by!(quote_id: body.fetch("quote_id"))
    assert_equal price, quote.price_version
    assert_equal experiment, quote.pricing_experiment
    assert_equal 2_500_000, body.fetch("list_price")
    assert_equal 1_900_000, body.fetch("offered_price")

    event = @earthodic.commercial_events.where(event_type: "quote_created").order(:created_at).last
    assert_equal event.exportable_value, event.value
    refute_includes event.value.keys, "product_name"
    refute_includes event.value.keys, "raw_evidence_payloads"
  end

  test "quote only products require manual offered price" do
    assert_no_difference -> { @earthodic.pricing_quotes.count } do
      post "/v1/pricing/quotes",
        params: { quote: { product_code: "recyclability_claim_evidence" } }.to_json,
        headers: api_headers(EARTHODIC_TOKEN)
    end

    assert_response :bad_request
    assert_includes JSON.parse(response.body).dig("error", "message"), "quote-only"

    assert_difference -> { @earthodic.pricing_quotes.count }, 1 do
      post "/v1/pricing/quotes",
        params: {
          quote: {
            product_code: "recyclability_claim_evidence",
            project_code: "PRJ-EARTH-APP-001",
            pricing_unit: "material_sku",
            currency: "AUD",
            offered_price_cents: 1_230_000
          }
        }.to_json,
        headers: api_headers(EARTHODIC_TOKEN)
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_nil body.fetch("list_price")
    assert_equal 1_230_000, body.fetch("offered_price")
    assert_equal "recyclability_claim_evidence", body.fetch("product_code")
  end

  test "tenant isolation blocks cross organization catalog quotes and artifacts" do
    post "/v1/pricing/quotes",
      params: { quote: { product_code: "application_qualification" } }.to_json,
      headers: api_headers(DIT_TOKEN)

    assert_response :bad_request
    assert_empty @dit.pricing_quotes.where(product_code: "application_qualification")

    get "/v1/pricing/quotes/QUOTE-EARTH-APP-001", headers: api_headers(DIT_TOKEN)
    assert_response :not_found

    get "/api/v1/artifacts/AE-AU-000184", headers: api_headers(EARTHODIC_TOKEN)
    assert_response :not_found

    invalid_price = @dit.price_versions.build(
      product_code: "application_qualification",
      product_version: "1.2",
      currency: "AUD",
      pricing_unit: "application",
      effective_from: Time.current,
      status: "active"
    )
    assert_not invalid_price.valid?
    assert_includes invalid_price.errors[:product_code].join, "not enabled"
  end

  private

  def api_headers(token)
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
end
