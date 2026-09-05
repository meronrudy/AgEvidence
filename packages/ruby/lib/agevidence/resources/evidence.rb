module AgEvidence
  module Resources
    class Evidence
      def initialize(client)
        @client = client
      end

      def create(payload, idempotency_key: nil)
        @client.request("POST", "/evidence", json: payload, idempotency_key: idempotency_key)
      end

      def get(id)
        @client.request("GET", "/evidence/#{id}")
      end
    end
  end
end
