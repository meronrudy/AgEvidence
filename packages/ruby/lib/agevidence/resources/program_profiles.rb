module AgEvidence
  module Resources
    class ProgramProfiles
      def initialize(client)
        @client = client
      end

      def list
        @client.request("GET", "/program_profiles")
      end

      def get(id)
        @client.request("GET", "/program_profiles/#{id}")
      end
    end
  end
end
