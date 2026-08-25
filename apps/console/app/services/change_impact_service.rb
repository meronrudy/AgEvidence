class ChangeImpactService
  def self.mark_project_evaluations_stale!(project:, actor: nil, reason:, metadata: {})
    project.evaluations.where(status: "current").find_each do |evaluation|
      evaluation.mark_stale!(metadata: metadata.merge(reason: reason, actor_id: actor&.id))
    end
  end

  def self.mark_profile_evaluations_stale!(profile:, actor: nil, reason:, metadata: {})
    profile.evaluations.where(status: "current").find_each do |evaluation|
      evaluation.mark_stale!(metadata: metadata.merge(reason: reason, actor_id: actor&.id))
    end
  end
end
