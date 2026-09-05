require "test_helper"

class ApiV1Test < ActionDispatch::IntegrationTest
  setup do
    seed_demo!
  end

  test "api key authenticates by digest and is not raw token" do
    key = ApiKey.find_by!(key_code: "KEY-001")

    assert_equal key, ApiKey.authenticate("agev_live_demo_7f91")
    refute_equal "agev_live_demo_7f91", key.token_digest
  end

  test "idempotent source record retry returns original response" do
    headers = {
      "Authorization" => "Bearer agev_live_demo_7f91",
      "Content-Type" => "application/json",
      "Idempotency-Key" => "sr-idempotent-test"
    }
    payload = {
      source_system: "Partner Portal",
      document_id: "DOC-API-001",
      evidence_type: "source_manifest",
      evidence_class: "controlled_source",
      controlled_uri: "https://sources.example/DOC-API-001",
      commitment: "sha256:#{SecureRandom.hex(16)}",
      disclosure_status: "available",
      status: "received"
    }

    assert_difference -> { SourceRecord.count }, 1 do
      post "/api/v1/projects/PRJ-AU-00041/source-records", params: payload.to_json, headers: headers
    end
    first_body = JSON.parse(response.body)
    assert_response :created

    assert_no_difference -> { SourceRecord.count } do
      post "/api/v1/projects/PRJ-AU-00041/source-records", params: payload.to_json, headers: headers
    end
    assert_response :created
    assert_equal first_body.fetch("data").fetch("record_code"), JSON.parse(response.body).fetch("data").fetch("record_code")
  end

  test "sdk shaped evidence ingestion resolves tenant workspace from api key" do
    headers = {
      "Authorization" => "Bearer agev_live_demo_7f91",
      "Content-Type" => "application/json",
      "Idempotency-Key" => "evt-api-99232"
    }
    payload = {
      type: "InterventionEvent",
      schema: "agevidence.intervention_event.v1",
      external_id: "dit-evt-99232",
      subject: { cohort_id: "C-18" },
      intervention: { product_lot: "PL-443" }
    }

    assert_difference -> { EvidenceRecord.where(record_type: "intervention_event").count }, 1 do
      post "/api/v1/evidence", params: payload.to_json, headers: headers
    end

    assert_response :created
    assert_equal "EVT-99232", response.parsed_body.dig("data", "id")
    assert_equal "dit-production", EvidenceRecord.find_by!(record_code: "EVT-99232").project.slug
  end

  test "invalid api payload uses documented error envelope" do
    post "/api/v1/projects/PRJ-AU-00041/source-records",
      params: {
        source_system: "Partner Portal",
        document_id: "DOC-API-002",
        evidence_type: "source_manifest",
        evidence_class: "controlled_source",
        controlled_uri: "file:///tmp/raw.csv",
        commitment: "bad",
        disclosure_status: "available",
        status: "received"
      }.to_json,
      headers: {
        "Authorization" => "Bearer agev_live_demo_7f91",
        "Content-Type" => "application/json"
      }

    assert_response :unprocessable_entity
    assert_equal "error-response.v0", JSON.parse(response.body).fetch("contract_version")
  end

  test "artifact verification records delegated verifier result" do
    assert_difference -> { VerifierResult.count }, 1 do
      post "/api/v1/artifacts/AE-AU-000184/verify", headers: { "Authorization" => "Bearer agev_test_demo_2a10" }
    end

    assert_response :success
    assert_includes %w[pending_external_verifier locally_consistent failed], JSON.parse(response.body).dig("data", "verifier_result_status")
  end

  test "api records reliance event without changing artifact" do
    artifact = Artifact.find_by!(artifact_code: "AE-AU-000184")
    original_digest = artifact.digest

    assert_difference -> { RelianceEvent.count }, 1 do
      post "/api/v1/artifacts/AE-AU-000184/reliance-events",
        params: {
          relying_party: "Recipient application",
          relying_party_role: "recipient",
          reliance_kind: "assurance",
          status: "recorded"
        }.to_json,
        headers: {
          "Authorization" => "Bearer agev_test_demo_2a10",
          "Content-Type" => "application/json"
        }
    end

    assert_response :created
    assert_equal original_digest, artifact.reload.digest
  end

  test "api retrieves dotted contract schema version" do
    get "/api/v1/schemas/artifact-manifest.v0", headers: { "Authorization" => "Bearer agev_live_demo_7f91" }

    assert_response :success
    assert_equal "artifact-manifest.v0", response.parsed_body.dig("data", "contract_version")
  end
end
