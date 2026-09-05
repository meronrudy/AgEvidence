module AgEvidence
  module Resources
    class Evaluations
      def initialize(client)
        @client = client
      end

      def list
        @client.request("GET", "/evaluations")
      end

      def get(id)
        @client.request("GET", "/evaluations/#{id}")
      end
    end
  end
end
