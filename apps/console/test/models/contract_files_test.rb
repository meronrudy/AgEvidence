require "test_helper"

class ContractFilesTest < ActiveSupport::TestCase
  CONTRACTS = %w[
    artifact-manifest.v0.json
    verifier-result.v0.json
    verifier-report.v1.json
    webhook-envelope.v0.json
    error-response.v0.json
  ].freeze

  test "contract files are versioned with positive and negative fixtures" do
    CONTRACTS.each do |filename|
      contract = JSON.parse(protocol_schema_path(filename).read)

      assert contract.fetch("$schema").present?, filename
      assert contract.fetch("$id").present?, filename
      assert contract.fetch("contract_version").present?, filename
      assert contract.fetch("examples").any?, filename
      assert contract.fetch("x-negative_examples").any?, filename
    end
  end

  test "integration event signer produces versioned signed envelope" do
    seed_demo!
    organization = Organization.find_by!(name: "DIT AgTech")

    envelope = IntegrationEventSigner.build(
      event_name: "statement.issued",
      organization: organization,
      payload: { "statement_code" => "AE-AU-000184" },
      secret: "secret",
      key_id: "whsec_test"
    )

    assert_equal "webhook-envelope.v0", envelope.fetch("contract_version")
    assert_equal "hmac-sha256", envelope.dig("signature", "algorithm")
    assert_equal "whsec_test", envelope.dig("signature", "key_id")
    assert envelope.dig("signature", "value").present?
  end

  private

  def protocol_schema_path(filename)
    Rails.root.join("..", "..", "protocol", "schemas", filename).expand_path
  end
end
