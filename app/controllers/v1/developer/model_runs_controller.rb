module V1
  module Developer
    class ModelRunsController < BaseController
      def create
        project = current_organization.projects.find_by!(project_code: params[:project_id])
        adapter_id = params[:adapter_id]
        
        # Validate adapter exists and belongs to project
        adapter = project.adapters.find_by(id: adapter_id)
        unless adapter
          render_error('not_found', 'Adapter not found or does not belong to project', :not_found)
          return
        end
        
        # Create ModelRun with status = queued
        model_run = project.model_runs.create!(
          adapter_id: adapter_id,
          status: :queued,
          commitment: project.latest_commitment
        )
        
        # Create Operation with operation_type = model_run, status = queued
        Operation.create!(
          project: project,
          operation_type: 'model_run',
          operation_data: {
            model_run_id: model_run.id,
            status: 'queued'
          }
        )
        
        serializer = ModelRunSerializer.new(model_run)
        render json: serializer.serializable_hash, status: :accepted
      end
    end
  end
end