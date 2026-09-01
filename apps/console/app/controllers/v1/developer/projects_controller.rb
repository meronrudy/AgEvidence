module V1
  module Developer
    class ProjectsController < BaseController
      def create
        project = current_organization.projects.build(project_params)
        
        if project.save
          # Generate stable project_code and unique slug
          project.generate_code_and_slug!
          
          # Emit audit event
          AuditEvent.create!(
            organization: current_organization,
            event_type: 'project_created',
            event_data: {
              project_id: project.id,
              project_code: project.project_code,
              slug: project.slug
            }
          )
          
          serializer = DeveloperProjectSerializer.new(project)
          render json: serializer.serializable_hash, status: :created
        else
          render_error('validation_error', project.errors.full_messages.join(', '), :unprocessable_entity)
        end
      end

      def show
        project = current_organization.projects.find_by!(project_code: params[:id])
        serializer = DeveloperProjectSerializer.new(project)
        render json: serializer.serializable_hash
      end

      private

      def project_params
        params.permit(
          :name, :description, :target_claim, :funding_stage,
          :project_type, :external_project_id, :country_context_json
        )
      end
    end
  end
end