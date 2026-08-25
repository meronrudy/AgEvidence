class ModelRunRecordingJob < ApplicationJob
  queue_as :default

  def perform(project_id:, actor_id: nil, attributes:, candidates: [], metadata: {})
    project = Project.find(project_id)
    actor = User.find_by(id: actor_id)
    ModelRunRecordingService.create!(
      project: project,
      actor: actor,
      attributes: attributes,
      candidates: candidates,
      metadata: metadata
    )
  end
end
