require "test_helper"

class EarthodicProductFactoryE2ETest < ActionDispatch::IntegrationTest
  TOKEN = "earthodic_demo_2026"

  setup do
    seed_demo!
    @organization = Organization.find_by!(name: "Earthodic Demo")
    @project = @organization.projects.find_by!(project_code: "PRJ-EARTH-APP-001")
    @artifact = @project.artifact
  end

  test "earthodic seeded journey and commercial api path produce filtered telemetry" do
    assert_equal "SR-EARTH-LAB-001", @project.source_records.first.record_code
    assert @project.evidence_records.exists?(record_code: "EV-EARTH-LAB-001")
    assert_equal "resolved", @project.gaps.find_by!(gap_code: "GAP-EARTH-APP-001").status
    assert_equal "decided", @project.reviews.find_by!(review_code: "RV-EARTH-001").state
    assert_equal "Qualified with conditions", @project.evaluations.find_by!(evaluation_code: "EVAL-EARTH-APP-001").outcome
    assert_equal "QA-EARTH-APP-001", @artifact.artifact_code
    assert_equal "application_qualification", @artifact.artifact.fetch("portfolio_product_code")

    post "/v1/pricing/quotes",
      params: {
        quote: {
          product_code: "application_qualification",
          project_code: @project.project_code,
          pricing_unit: "application",
          currency: "AUD",
          offered_price_cents: 1_900_000
        }
      }.to_json,
      headers: api_headers
    assert_response :created
    quote_id = JSON.parse(response.body).fetch("quote_id")

    post "/v1/artifact-orders",
      params: { artifact_order: { quote_id: quote_id } }.to_json,
      headers: api_headers
    assert_response :created
    order_id = JSON.parse(response.body).fetch("order_id")

    assert_difference -> { @organization.commercial_outcomes.where(state: "won").count }, 1 do
      post "/v1/artifact-orders/#{order_id}/checkout", headers: api_headers
    end
    assert_response :success

    assert_difference -> { @project.reliance_events.count }, 1 do
      post "/api/v1/artifacts/#{@artifact.artifact_code}/reliance-events",
        params: {
          relying_party: "Converter procurement team",
          relying_party_role: "recipient",
          reliance_kind: "procurement",
          status: "recorded"
        }.to_json,
        headers: api_headers
    end
    assert_response :created

    events = @organization.commercial_events.order(:created_at).last(4)
    assert_equal %w[quote_created order_created quote_accepted reliance_recorded], events.map(&:event_type)
    events.each do |event|
      assert_equal event.exportable_value, event.value
      refute_includes event.value.keys, "customer_identity"
      refute_includes event.value.keys, "raw_evidence_payloads"
      refute_includes event.value.keys, "proprietary_model_parameters"
      refute_includes event.value.keys, "contract_text"
      refute_includes event.value.keys, "confidential_geometries"
    end

    checkout_outcome = @organization.commercial_outcomes.order(:created_at).last
    assert_equal "application_qualification", checkout_outcome.product_code
    assert_equal 1_900_000, checkout_outcome.accepted_price_cents
    assert_equal 1_200_000, checkout_outcome.recurring_value_cents
    assert_equal 19, checkout_outcome.sales_cycle_days
  end

  private

  def api_headers
    {
      "Authorization" => "Bearer #{TOKEN}",
      "Content-Type" => "application/json"
    }
  end
end
