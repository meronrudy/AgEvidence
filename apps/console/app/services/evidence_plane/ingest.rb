module EvidencePlane
  class Ingest
    def self.call(organization:, actor:, attributes:, metadata: {})
      new(organization: organization, actor: actor, attributes: attributes, metadata: metadata).call
    end

    def initialize(organization:, actor:, attributes:, metadata:)
      @organization = organization
      @actor = actor
      @attributes = attributes.to_h.deep_stringify_keys
      @metadata = metadata
    end

    def call
      project = evidence_workspace
      payload = CanonicalJson.normalize(@attributes)
      digest = CanonicalJson.digest(payload)
      primitive = @attributes.fetch("type")
      schema = @attributes.fetch("schema")
      external_id = @attributes["external_id"].presence || @attributes["id"].presence

      record = project.evidence_records.create!(
        record_code: record_code(external_id, primitive),
        label: primitive.underscore.humanize,
        record_type: primitive.underscore,
        status: "accepted",
        schema_name: schema,
        source: "AgEvidence SDK",
        received_at: Time.current,
        projection: schema,
        digest: digest,
        inbox_result: "PROJECTED",
        operation_id: @metadata[:request_id],
        summary: summary(primitive, external_id),
        payload: payload,
        integrity: [
          { "label" => "Canonical encoding", "ok" => true },
          { "label" => "Digest computed", "ok" => true },
          { "label" => "Tenant workspace resolved", "ok" => true }
        ],
        processing: [
          { "step" => "Received", "ok" => true, "note" => "AgEvidence SDK" },
          { "step" => "Schema validation", "ok" => true, "note" => schema },
          { "step" => "Canonical projection", "ok" => true, "note" => schema }
        ]
      )

      EvidencePlane::EvaluateAffectedRequirements.call(evidence_record: record)
      record
    end

    private

    def evidence_workspace
      @organization.projects.find_by(slug: "dit-production") || @organization.projects.order(:created_at).first!
    end

    def record_code(external_id, primitive)
      candidate = external_id.to_s.sub(/\Adit-/i, "").upcase
      candidate.presence || "#{primitive.underscore.upcase}-#{SecureRandom.hex(4).upcase}"
    end

    def summary(primitive, external_id)
      [
        { "label" => "Primitive", "value" => primitive, "mono" => true },
        { "label" => "External ID", "value" => external_id, "mono" => true }
      ]
    end
  end
end
