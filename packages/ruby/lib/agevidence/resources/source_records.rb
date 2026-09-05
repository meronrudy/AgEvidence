module AgEvidence
  module Resources
    class SourceRecords
      def initialize(client)
        @client = client
      end

      def submit(project_code:, source_system:, document_id:, evidence_type:, controlled_uri:, commitment:, evidence_class: nil, disclosure_status: nil, status: nil, idempotency_key: nil)
        @client.request(
          "POST",
          "/projects/#{project_code}/source-records",
          json: {
            source_system: source_system,
            document_id: document_id,
            evidence_type: evidence_type,
            evidence_class: evidence_class,
            controlled_uri: controlled_uri,
            commitment: commitment,
            disclosure_status: disclosure_status,
            status: status
          }.compact,
          idempotency_key: idempotency_key
        )
      end

      def get(project_code:, record_code:)
        @client.request("GET", "/projects/#{project_code}/source-records/#{record_code}")
      end
    end
  end
end
