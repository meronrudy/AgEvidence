module AgEvidence
  module Resources
    class Statements
      def initialize(client)
        @client = client
      end

      def list
        @client.request("GET", "/statements")
      end

      def get(id)
        @client.request("GET", "/statements/#{id}")
      end

      def share(id, recipient:, access_level: "statement_and_summary", expires_in_days: nil, idempotency_key: nil)
        @client.request(
          "POST",
          "/statements/#{id}/shares",
          json: { recipient: recipient, access_level: access_level, expires_in_days: expires_in_days }.compact,
          idempotency_key: idempotency_key
        )
      end
    end
  end
end
