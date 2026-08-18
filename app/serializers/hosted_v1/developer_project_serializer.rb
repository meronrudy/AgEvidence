module HostedV1
  class DeveloperProjectSerializer
    def initialize(project)
      @project = project
    end

    def serializable_hash
      {
        id: @project.id,
        project_code: @project.project_code,
        name: @project.name,
        description: @project.description,
        target_claim: @project.target_claim,
        funding_stage: @project.funding_stage,
        project_type: @project.project_type,
        external_project_id: @project.external_project_id,
        country_context_json: @project.country_context_json,
        created_at: @project.created_at.iso8601,
        updated_at: @project.updated_at.iso8601
      }
    end
  end
end