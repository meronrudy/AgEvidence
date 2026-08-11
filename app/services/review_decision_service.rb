class ReviewDecisionService
  def self.create!(review:, decision:, actor:, rationale:, limitation:, metadata: {})
    Review.transaction do
      review.update!(state: "decided")
      review_decision = review.review_decisions.create!(
        decision_code: "RD-#{SecureRandom.hex(4).upcase}",
        decision: decision,
        reviewer: actor.full_name,
        user: actor,
        recorded_at: Time.current,
        rationale: rationale.presence || "No rationale supplied.",
        limitation: limitation.presence
      )

      AuditEvent.log!(
        action: "review_decision_created",
        actor: actor,
        organization: review.project.organization,
        auditable: review_decision,
        metadata: metadata.merge(review_code: review.review_code, decision: decision)
      )

      review_decision
    end
  end
end
