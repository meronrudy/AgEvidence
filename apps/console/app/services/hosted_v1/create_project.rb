module HostedV1
  class CreateProject
    def self.call(organization:, params:)
      new(organization, params).call
    end

    def initialize(organization, params)
      @organization = organization
      @params = params
    end

    def call
      project = @organization.projects.build(project_params)
      
      if project.save
        project.generate_code_and_slug!
        
        AuditEvent.create!(
          organization: @organization,
          event_type: 'project_created',
          event_data: {
            project_id: project.id,
            project_code: project.project_code,
            slug: project.slug
          }
        )
        
        project
      else
        raise ActiveRecord::RecordInvalid.new(project)
      end
    end

    private

    def project_params
      @params.permit(
        :name, :description, :target_claim, :funding_stage,
        :project_type, :external_project_id, :country_context_json
      )
    end
  end
end