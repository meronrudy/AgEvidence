module Api
  module V1
    class StatementSharesController < BaseController
      def create
        require_scope!("statements:share")
        statement = policy_scope(Artifact).find_by!(artifact_code: params[:id])
        share = statement.statement_shares.create!(
          access_level: share_params[:access_level].presence || "statement_and_summary",
          expires_at: Time.current + expires_in_days.days
        )
        envelope({
          "statement_id" => statement.artifact_code,
          "access_level" => share.access_level,
          "expires_at" => share.expires_at.utc.iso8601,
          "url" => shared_statement_url(share.token)
        }, status: :created)
      end

      private

      def share_params
        params.fetch(:statement_share, params).permit(:access_level, :expires_in_days)
      end

      def expires_in_days
        days = share_params[:expires_in_days].to_i
        days.positive? ? days : 30
      end
    end
  end
end
