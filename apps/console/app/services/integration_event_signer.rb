require "openssl"

class IntegrationEventSigner
  CONTRACT_VERSION = "webhook-envelope.v0"

  def self.build(event_name:, organization:, payload:, secret:, key_id:, occurred_at: Time.current)
    envelope = {
      "contract_version" => CONTRACT_VERSION,
      "event_name" => event_name,
      "event_id" => "evt_#{SecureRandom.hex(12)}",
      "occurred_at" => occurred_at.utc.iso8601,
      "organization_code" => organization.id.to_s,
      "payload" => payload
    }
    signature_value = OpenSSL::HMAC.hexdigest("SHA256", secret, StableJson.generate(envelope))
    envelope.merge(
      "signature" => {
        "algorithm" => "hmac-sha256",
        "key_id" => key_id,
        "value" => signature_value
      }
    )
  end
end
