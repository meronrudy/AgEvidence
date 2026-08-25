module HostedV1
  class ModelRunSerializer
    def initialize(model_run)
      @model_run = model_run
    end

    def serializable_hash
      {
        id: @model_run.id,
        run_code: @model_run.run_code,
        project_id: @model_run.project_id,
        adapter_id: @model_run.adapter_id,
        status: @model_run.status,
        output: @model_run.output,
        started_at: @model_run.started_at&.iso8601,
        completed_at: @model_run.completed_at&.iso8601,
        created_at: @model_run.created_at.iso8601,
        updated_at: @model_run.updated_at.iso8601
      }
    end
  end
end