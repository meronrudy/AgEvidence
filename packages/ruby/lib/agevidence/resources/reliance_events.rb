module AgEvidence
  module Resources
    class RelianceEvents
      def initialize(client)
        @client = client
      end

      def create(artifact_code:, relying_party:, relying_party_role:, reliance_scope:, outcome:, metadata: nil, idempotency_key: nil)
        @client.request(
          "POST",
          "/artifacts/#{artifact_code}/reliance-events",
          json: {
            relying_party: relying_party,
            relying_party_role: relying_party_role,
            reliance_scope: reliance_scope,
            outcome: outcome,
            metadata: metadata
          }.compact,
          idempotency_key: idempotency_key
        )
      end
    end
  end
end
