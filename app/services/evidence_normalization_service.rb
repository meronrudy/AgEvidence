class EvidenceNormalizationService
  def self.create_from_source!(source_record:, actor:, projection:, schema_name:, payload:, status: "accepted", metadata: {})
    new(
      source_record: source_record,
      actor: actor,
      projection: projection,
      schema_name: schema_name,
      payload: payload,
      status: status,
      metadata: metadata
    ).create!
  end

  def initialize(source_record:, actor:, projection:, schema_name:, payload:, status:, metadata:)
    @source_record = source_record
    @actor = actor
    @projection = projection
    @schema_name = schema_name
    @payload = payload
    @status = status
    @metadata = metadata
  end

  def create!
    EvidenceRecord.transaction do
      normalized_payload = CanonicalJson.normalize(@payload.merge(
        "source_record_code" => @source_record.record_code,
        "source_commitment" => @source_record.commitment,
        "contract_version" => "evidence-record.v0"
      ))
      digest = CanonicalJson.digest(normalized_payload)

      evidence_record = @source_record.project.evidence_records.create!(
        source_record: @source_record,
        record_code: "EV-#{SecureRandom.hex(5).upcase}",
        label: @source_record.evidence_type.to_s.titleize,
        record_type: @source_record.evidence_type,
        status: @status,
        schema_name: @schema_name,
        source: @source_record.source_system,
        received_at: Time.current,
        projection: @projection,
        digest: digest,
        inbox_result: @status == "accepted" ? "Accepted" : @status.to_s.humanize,
        operation_id: @metadata[:request_id],
        summary: [
          { "label" => "Source record", "value" => @source_record.record_code, "mono" => true },
          { "label" => "Document", "value" => @source_record.document_id, "mono" => true },
          { "label" => "Commitment", "value" => @source_record.commitment, "mono" => true }
        ],
        payload: normalized_payload,
        integrity: [
          { "label" => "Source commitment recorded", "ok" => true },
          { "label" => "Canonical projection digest", "ok" => true },
          { "label" => "Project boundary matched", "ok" => true }
        ],
        processing: [
          { "step" => "Source intake", "ok" => true, "note" => @source_record.record_code },
          { "step" => "Normalize", "ok" => true, "note" => @projection },
          { "step" => "Digest", "ok" => true, "note" => digest }
        ]
      )

      AuditEvent.log!(
        action: "evidence_normalized",
        actor: @actor,
        organization: @source_record.organization,
        auditable: evidence_record,
        metadata: @metadata.merge(source_record_code: @source_record.record_code, digest: digest)
      )

      evidence_record
    end
  end
end
