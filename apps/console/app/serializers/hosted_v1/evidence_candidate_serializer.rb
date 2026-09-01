module HostedV1
  class EvidenceCandidateSerializer
    def initialize(evidence_candidate)
      @evidence_candidate = evidence_candidate
    end

    def serializable_hash
      {
        id: @evidence_candidate.id,
        model_run_id: @evidence_candidate.model_run_id,
        statement_text: @evidence_candidate.statement_text,
        confidence_score: @evidence_candidate.confidence_score,
        status: @evidence_candidate.status,
        created_at: @evidence_candidate.created_at.iso8601,
        updated_at: @evidence_candidate.updated_at.iso8601
      }
    end
  end
end