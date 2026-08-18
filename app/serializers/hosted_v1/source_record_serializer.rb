module HostedV1
  class SourceRecordSerializer
    def initialize(source_record)
      @source_record = source_record
    end

    def serializable_hash
      {
        id: @source_record.id,
        project_id: @source_record.project_id,
        document_id: @source_record.document_id,
        source_type: @source_record.source_type,
        payload: @source_record.payload,
        schema: @source_record.schema,
        record_type: @source_record.record_type,
        received_at: @source_record.received_at.iso8601,
        digest: @source_record.digest,
        processing_status: @source_record.processing_status,
        evidence_record_id: @source_record.evidence_record_id,
        source_record_link: @source_record.source_record_link
      }
    end
  end
end