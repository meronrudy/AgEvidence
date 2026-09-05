module AgEvidence
  module Resources
    class Artifacts
      def initialize(client)
        @client = client
      end

      def get(artifact_code)
        @client.request("GET", "/artifacts/#{artifact_code}")
      end

      def verify(artifact_code, idempotency_key: nil)
        @client.request("POST", "/artifacts/#{artifact_code}/verify", json: {}, idempotency_key: idempotency_key)
      end
    end
  end
end
