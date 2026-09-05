class DeterminationPublisher
  def self.publish!(evaluation:, actor:, outcome:, limitations:, supersedes: nil, metadata: {})
    new(
      evaluation: evaluation,
      actor: actor,
      outcome: outcome,
      limitations: limitations,
      supersedes: supersedes,
      metadata: metadata
    ).publish!
  end

  def initialize(evaluation:, actor:, outcome:, limitations:, supersedes:, metadata:)
    @evaluation = evaluation
    @project = evaluation.project
    @profile = evaluation.program_profile
    @actor = actor
    @outcome = outcome
    @limitations = Array(limitations)
    @supersedes = supersedes
    @metadata = metadata
  end

  def publish!
    validate_publication!

    Determination.transaction do
      @supersedes&.supersede!(metadata: @metadata.merge(reason: "Superseded by a new published determination"))

      result = {
        "contract_version" => "determination-result.v0",
        "evaluation_code" => @evaluation.evaluation_code,
        "profile_version" => @evaluation.profile_version,
        "input_digest" => @evaluation.input_digest,
        "limitations" => @limitations
      }

      determination = Determination.create!(
        project: @project,
        program_profile: @profile,
        evaluation: @evaluation,
        supersedes_determination: @supersedes,
        determination_code: "DET-#{SecureRandom.hex(5).upcase}",
        project_name: @project.name,
        outcome: @outcome,
        adapter: "#{@profile.code} #{@profile.profile_version}",
        digest: ApplicationDigest.sha256(result),
        published_at: Time.current,
        status: "published",
        result: result
      )

      AuditEvent.log!(
        action: "determination_published",
        actor: @actor,
        organization: @project.organization,
        auditable: determination,
        metadata: @metadata.merge(determination_code: determination.determination_code, evaluation_code: @evaluation.evaluation_code)
      )

      determination
    end
  end

  private

  def validate_publication!
    raise ArgumentError, "evaluation profile version is required" if @evaluation.profile_version.blank?
    raise ArgumentError, "evaluation input digest is required" if @evaluation.input_digest.blank?
    raise ArgumentError, "evaluation is stale" if @evaluation.stale?
    raise ArgumentError, "blocking gaps remain" if @project.gaps.open.blocking.exists?
    raise ArgumentError, "human reviews are still open" if @project.reviews.open.exists?
    raise ArgumentError, "at least one explicit limitation is required" if @limitations.blank?
  end
end
