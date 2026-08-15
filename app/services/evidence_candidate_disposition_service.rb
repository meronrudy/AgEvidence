class EvidenceCandidateDispositionService
  def self.record!(candidate:, status:, reason:, actor:, metadata: {})
    new(candidate: candidate, status: status, reason: reason, actor: actor, metadata: metadata).record!
  end

  def initialize(candidate:, status:, reason:, actor:, metadata:)
    @candidate = candidate
    @status = status
    @reason = reason
    @actor = actor
    @metadata = metadata
  end

  def record!
    EvidenceCandidate.transaction do
      disposition = @candidate.evidence_candidate_dispositions.create!(
        status: @status,
        reason: @reason,
        actor: @actor,
        recorded_at: Time.current,
        metadata: @metadata
      )

      @candidate.update!(
        status: @status,
        disposition_reason: @reason,
        reviewed_by_user: @actor,
        reviewed_at: disposition.recorded_at
      )

      AuditEvent.log!(
        action: "evidence_candidate_disposition_recorded",
        actor: @actor,
        organization: @candidate.organization,
        auditable: disposition,
        metadata: @metadata.merge(candidate_code: @candidate.candidate_code, status: @status)
      )

      disposition
    end
  end
end
