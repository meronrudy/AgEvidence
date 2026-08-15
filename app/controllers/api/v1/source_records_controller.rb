module Api
  module V1
    class SourceRecordsController < BaseController
      def create
        require_scope!("source_records:create")
        project = policy_scope(Project).find_by!(project_code: params[:project_code])
        authorize SourceRecord.new(project: project, organization: project.organization)

        if (stored = stored_idempotent_response)
          return envelope(stored.response, status: stored.status)
        end

        source_record = SourceRecordIntakeService.create!(
          project: project,
          actor: api_actor,
          attributes: source_record_params,
          metadata: audit_metadata
        )
        response_payload = serialize_source_record(source_record)
        store_idempotent_response(response_payload, 201)
        envelope(response_payload, status: :created)
      end

      def show
        require_scope!("source_records:read")
        project = policy_scope(Project).find_by!(project_code: params[:project_code])
        source_record = policy_scope(SourceRecord).where(project: project).find_by!(record_code: params[:record_code])
        authorize source_record
        envelope(serialize_source_record(source_record))
      end

      private

      def source_record_params
        source_params = params[:source_record].presence || params
        ActionController::Parameters.new(source_params.to_unsafe_h).permit(
          :record_code,
          :source_system,
          :document_id,
          :evidence_type,
          :evidence_class,
          :controlled_uri,
          :commitment,
          :disclosure_status,
          :status,
          metadata: {}
        )
      end

      def serialize_source_record(source_record)
        source_record.public_bundle_payload.merge(
          "project_code" => source_record.project.project_code,
          "created_at" => source_record.created_at.utc.iso8601
        )
      end

      def idempotency_key
        request.headers["Idempotency-Key"].to_s.presence
      end

      def stored_idempotent_response
        return unless idempotency_key

        ApiIdempotencyKey.find_by(
          organization: current_organization,
          key: idempotency_key,
          method: request.request_method,
          path: request.path
        )
      end

      def store_idempotent_response(response_payload, status)
        return unless idempotency_key

        ApiIdempotencyKey.create!(
          organization: current_organization,
          key: idempotency_key,
          method: request.request_method,
          path: request.path,
          status: status,
          response: response_payload
        )
      end
    end
  end
end
