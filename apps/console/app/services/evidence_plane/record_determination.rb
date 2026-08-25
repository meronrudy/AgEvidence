module EvidencePlane
  class RecordDetermination
    def self.call(review:, decision:, rationale:, qualification:, actor:, metadata: {})
      Review.transaction do
        review_decision = ReviewDecisionService.create!(
          review: review,
          decision: decision,
          actor: actor,
          rationale: rationale,
          limitation: qualification,
          metadata: metadata
        )

        profile = ProgramProfile.find_by!(code: "AU_METHANE_INTERVENTION_V1")
        evaluation = review.project.evaluations.where(program_profile: profile).order(evaluated_at: :desc).first
        determination = DeterminationService.create!(
          program_profile: profile,
          project: review.project,
          evaluation: evaluation,
          outcome: decision,
          adapter: "#{profile.code} #{profile.profile_version}",
          digest: CanonicalJson.digest({
            "review_decision" => review_decision.decision_code,
            "decision" => decision,
            "qualification" => qualification
          }),
          actor: actor,
          metadata: metadata
        )
        determination.update!(
          result: determination.result.merge(
            "rationale" => rationale,
            "qualification" => qualification,
            "reviewer" => actor.full_name,
            "review_decision_code" => review_decision.decision_code
          )
        )
        determination
      end
    end
  end
end
