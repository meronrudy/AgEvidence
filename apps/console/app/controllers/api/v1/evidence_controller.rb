module Api
  module V1
    class EvidenceController < BaseController
      def create
        require_scope!("evidence:create")
        record = EvidencePlane::Ingest.call(
          organization: current_organization,
          actor: api_actor,
          attributes: evidence_params,
          metadata: audit_metadata
        )
        envelope(serialize_record(record), status: :created)
      rescue KeyError => e
        error_envelope(code: "invalid_request", message: "Missing required field: #{e.key}", status: :unprocessable_entity)
      end

      def show
        require_scope!("evidence:read")
        record = policy_scope(EvidenceRecord).find_by!(record_code: params[:id])
        envelope(serialize_record(record))
      end

      private

      def evidence_params
        source_params = params[:evidence].presence || params
        ActionController::Parameters.new(source_params.to_unsafe_h).permit(
          :type,
          :schema,
          :external_id,
          :id,
          subject: {},
          intervention: {},
          observation: {},
          operation: {},
          model: {},
          metadata: {}
        )
      end

      def serialize_record(record)
        {
          "id" => record.record_code,
          "type" => record.record_type.camelize(:upper),
          "schema" => record.schema_name,
          "status" => record.status,
          "digest" => record.digest,
          "received_at" => record.received_at.utc.iso8601,
          "operation_id" => record.operation_id
        }
      end
    end
  end
end
