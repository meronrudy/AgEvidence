module Api
  module V1
    class EvaluationsController < BaseController
      def index
        require_scope!("evaluations:read")
        envelope(policy_scope(Evaluation).includes(:program_profile).order(evaluated_at: :desc).map { |evaluation| serialize(evaluation) })
      end

      def show
        require_scope!("evaluations:read")
        envelope(serialize(policy_scope(Evaluation).find_by!(evaluation_code: params[:id])))
      end

      private

      def serialize(evaluation)
        {
          "id" => evaluation.evaluation_code,
          "profile" => evaluation.program_profile.code,
          "profile_version" => evaluation.profile_version,
          "outcome" => evaluation.outcome,
          "status" => evaluation.result["plane_status"] || evaluation.outcome,
          "satisfied" => evaluation.satisfied,
          "evaluated_at" => evaluation.evaluated_at.utc.iso8601,
          "result" => evaluation.result
        }
      end
    end
  end
end
