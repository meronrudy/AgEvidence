module V1
  module Developer
    class SourceRecordsController < BaseController
      def create
        project = current_organization.projects.find_by!(project_code: params[:project_id])
        
        # Handle idempotency: same document_id + commitment → return existing
        existing = project.source_records.find_by(document_id: params[:document_id])
        if existing && existing.commitment == params[:commitment]
          serializer = SourceRecordSerializer.new(existing)
          render json: serializer.serializable_hash
          return
        end
        
        # Handle conflict: same document_id + different commitment → 409
        if existing && existing.commitment != params[:commitment]
          render_error('conflict', 'Source record with same document_id but different commitment already exists', :conflict)
          return
        end
        
        source_record = project.source_records.create!(source_record_params)
        
        # Emit audit event
        AuditEvent.create!(
          organization: current_organization,
          event_type: 'source_record_created',
          event_data: {
            project_id: project.id,
            source_record_id: source_record.id,
            document_id: source_record.document_id
          }
        )
        
        # Enqueue background job for processing
        ProjectSourceRecordJob.perform_later(source_record.id)
        
        serializer = SourceRecordSerializer.new(source_record)
        render json: serializer.serializable_hash, status: :created
      end

      def show
        project = current_organization.projects.find_by!(project_code: params[:project_id])
        source_record = project.source_records.find_by!(document_id: params[:document_id])
        serializer = SourceRecordSerializer.new(source_record)
        render json: serializer.serializable_hash
      end

      private

      def source_record_params
        params.permit(
          :document_id, :commitment, :source_type, :payload, :schema,
          :record_type, :received_at, :digest, :processing_status,
          :evidence_record_id, :source_record_link
        )
      end
    end
  end
end