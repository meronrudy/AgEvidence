class ProjectEvaluationService
  def self.evaluate!(project:, profile:, actor:, metadata: {})
    new(project: project, profile: profile, actor: actor, metadata: metadata).evaluate!
  end

  def initialize(project:, profile:, actor:, metadata:)
    @project = project
    @profile = profile
    @actor = actor
    @metadata = metadata
  end

  def evaluate!
    raise ArgumentError, "profile version is required" if @profile.profile_version.blank?

    accepted_evidence = @project.evidence_records.where(status: "accepted").order(:record_code)
    requirements = @profile.requirements.order(:requirement_code)
    satisfied_codes = requirements.select do |requirement|
      accepted = requirement.accepted_evidence
      accepted.any? && accepted_evidence.any? { |record| accepted.include?(record.schema_name) }
    end.map(&:requirement_code)
    unsatisfied_codes = requirements.map(&:requirement_code) - satisfied_codes
    input = {
      "project_code" => @project.project_code,
      "profile_code" => @profile.code,
      "profile_version" => @profile.profile_version,
      "evidence" => accepted_evidence.map { |record| { "record_code" => record.record_code, "digest" => record.digest } },
      "review_decisions" => @project.reviews.includes(:review_decisions).flat_map(&:review_decisions).map(&:decision_code).sort
    }
    input_digest = CanonicalJson.digest(input)
    outcome = unsatisfied_codes.empty? ? "Eligible" : "Eligible with conditions"

    Evaluation.transaction do
      evaluation = Evaluation.create!(
        program_profile: @profile,
        project: @project,
        evaluation_code: "EVAL-#{SecureRandom.hex(5).upcase}",
        project_name: @project.name,
        outcome: outcome,
        satisfied: "#{satisfied_codes.count} / #{requirements.count}",
        published: false,
        evaluated_at: Time.current,
        input_digest: input_digest,
        profile_version: @profile.profile_version,
        status: "current",
        result: {
          "contract_version" => "evaluation-result.v0",
          "input_digest" => input_digest,
          "profile_version" => @profile.profile_version,
          "machine_status" => "calculated",
          "human_status" => @project.reviews.open.exists? ? "open" : "complete",
          "satisfied_requirement_codes" => satisfied_codes,
          "unsatisfied_requirement_codes" => unsatisfied_codes
        }
      )

      AuditEvent.log!(
        action: "evaluation_created",
        actor: @actor,
        organization: @project.organization,
        auditable: evaluation,
        metadata: @metadata.merge(evaluation_code: evaluation.evaluation_code, input_digest: input_digest)
      )

      evaluation
    end
  end
end
