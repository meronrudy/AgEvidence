require "digest"

class GapDetectionService
  def self.record!(project:, requirement_code:, severity:, title:, explanation:, expected:, observed:, related_evidence: [], blocking: false, source_record: nil, evidence_record: nil, actor: nil, metadata: {})
    new(
      project: project,
      requirement_code: requirement_code,
      severity: severity,
      title: title,
      explanation: explanation,
      expected: expected,
      observed: observed,
      related_evidence: related_evidence,
      blocking: blocking,
      source_record: source_record,
      evidence_record: evidence_record,
      actor: actor,
      metadata: metadata
    ).record!
  end

  def initialize(project:, requirement_code:, severity:, title:, explanation:, expected:, observed:, related_evidence:, blocking:, source_record:, evidence_record:, actor:, metadata:)
    @project = project
    @requirement_code = requirement_code
    @severity = severity
    @title = title
    @explanation = explanation
    @expected = expected
    @observed = observed
    @related_evidence = related_evidence
    @blocking = blocking
    @source_record = source_record
    @evidence_record = evidence_record
    @actor = actor
    @metadata = metadata
  end

  def record!
    Gap.transaction do
      gap = @project.gaps.open.find_or_initialize_by(gap_code: deterministic_gap_code)
      gap.assign_attributes(
        requirement_code: @requirement_code,
        severity: @severity,
        title: @title,
        explanation: @explanation,
        expected: Array(@expected),
        observed: Array(@observed),
        related_evidence: Array(@related_evidence),
        action: "Resolve evidence requirement",
        status: "open",
        blocking: @blocking,
        source_record: @source_record,
        evidence_record: @evidence_record
      )
      created = gap.new_record?
      gap.save!

      AuditEvent.log!(
        action: created ? "gap_opened" : "gap_updated",
        actor: @actor,
        organization: @project.organization,
        auditable: gap,
        metadata: @metadata.merge(gap_code: gap.gap_code, requirement_code: @requirement_code)
      )

      gap
    end
  end

  private

  def deterministic_gap_code
    digest = Digest::SHA256.hexdigest([@project.project_code, @requirement_code, @title].join(":")).first(10).upcase
    "GAP-#{digest}"
  end
end
