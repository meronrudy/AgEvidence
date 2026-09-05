class ArtifactIssuanceService
  def self.issue!(artifact:, actor:, recipient: nil, access_level: "read", expires_in: 30.days, metadata: {})
    new(
      artifact: artifact,
      actor: actor,
      recipient: recipient,
      access_level: access_level,
      expires_in: expires_in,
      metadata: metadata
    ).issue!
  end

  def initialize(artifact:, actor:, recipient:, access_level:, expires_in:, metadata:)
    @artifact = artifact
    @actor = actor
    @recipient = recipient
    @access_level = access_level
    @expires_in = expires_in
    @metadata = metadata
  end

  def issue!
    Artifact.transaction do
      validate_issueable!
      @artifact.issue!(issued_by: @actor)
      Trust::Verifier.record_artifact!(artifact: @artifact, actor: @actor, metadata: @metadata)

      if @recipient
        ResourceGrant.grant_artifact_access(
          @recipient,
          @artifact,
          @actor,
          access_level: @access_level,
          expires_in: @expires_in
        )
      end

      AuditEvent.log!(
        action: "artifact_issued",
        actor: @actor,
        organization: @artifact.organization,
        auditable: @artifact,
        metadata: @metadata
      )

      CommercialTelemetry::Recorder.record!(
        event_type: "artifact_issued",
        organization: @artifact.organization,
        project: @artifact.project,
        product_code: product_code,
        value: {
          "organization_class" => "portfolio_company",
          "product_code" => product_code,
          "artifacts_generated" => @artifact.project.artifacts.count,
          "source_records_ingested" => @artifact.project.source_records.count,
          "evidence_records_generated" => @artifact.project.evidence_records.count,
          "model_or_evaluation_runs" => @artifact.project.model_runs.count + @artifact.project.evaluations.count,
          "reviewer_actions" => @artifact.project.reviews.joins(:review_decisions).count,
          "reliance_events" => @artifact.project.reliance_events.count
        }
      )

      @artifact
    end
  end

  private

  def validate_issueable!
    raise ArgumentError, "statement must be ready for issuance" unless @artifact.status.in?(%w[ready ready_with_qualification])
    raise ArgumentError, "statement is already issued" if @artifact.issued?

    determination = Determination.where(project: @artifact.project, status: "published").order(published_at: :desc).first
    raise ArgumentError, "published determination is required" unless determination

    evaluation = determination.evaluation || Evaluation.where(project: @artifact.project, program_profile: determination.program_profile).order(evaluated_at: :desc).first
    raise ArgumentError, "non-stale evaluation is required" unless evaluation && !evaluation.stale?
    raise ArgumentError, "blocking gaps remain" if @artifact.project.gaps.open.blocking.exists?
    raise ArgumentError, "required human reviews are open" if @artifact.project.reviews.open.exists?
  end

  def product_code
    @metadata[:product_code] ||
      @metadata["product_code"] ||
      @artifact.artifact["portfolio_product_code"] ||
      @artifact.project.metadata["product_code"]
  end
end
