module AgEvidence
  module Resources
    class Schemas
      def initialize(client)
        @client = client
      end

      def get(contract_version)
        @client.request("GET", "/schemas/#{contract_version}")
      end
    end
  end
end
