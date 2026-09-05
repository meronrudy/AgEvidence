module EvidencePlane
  class EvaluateAffectedRequirements
    PROFILE_CODE = "AU_METHANE_INTERVENTION_V1".freeze

    def self.call(evidence_record:)
      new(evidence_record: evidence_record).call
    end

    def initialize(evidence_record:)
      @evidence_record = evidence_record
      @project = evidence_record.project
    end

    def call
      profile = ProgramProfile.find_by(code: PROFILE_CODE)
      return unless profile

      evaluation = @project.evaluations.where(program_profile: profile).order(evaluated_at: :desc).first
      return unless evaluation

      evaluation.update!(
        evaluated_at: Time.current,
        input_digest: ApplicationDigest.sha256({
          "evaluation_code" => evaluation.evaluation_code,
          "trigger" => @evidence_record.record_code,
          "evidence_digest" => @evidence_record.digest
        }),
        result: evaluation.result.merge(
          "last_trigger" => @evidence_record.record_code,
          "affected_requirements" => affected_requirements
        )
      )

      @project.activities.create!(
        activity_code: "ACT-#{SecureRandom.hex(5).upcase}",
        occurred_at: Time.current,
        actor: "Evidence Plane",
        actor_kind: "system",
        title: "#{profile.name} reevaluated",
        detail: "#{@evidence_record.record_code} affected #{affected_requirements.length} requirements.",
        tone: "info"
      )

      evaluation
    end

    private

    def affected_requirements
      case @evidence_record.record_type
      when "intervention_event"
        %w[AE-METH-004 AE-METH-005 AE-METH-006 AE-METH-014]
      when "operational_event"
        %w[AE-METH-006 AE-METH-014]
      when "observation"
        %w[AE-METH-007 AE-METH-008 AE-METH-009]
      when "model_run"
        %w[AE-METH-010 AE-METH-011 AE-METH-012 AE-METH-013]
      else
        %w[AE-METH-001]
      end
    end
  end
end
