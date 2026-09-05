module AgEvidence
  module Resources
    class Reviews
      def initialize(client)
        @client = client
      end

      def list
        @client.request("GET", "/reviews")
      end
    end
  end
end
