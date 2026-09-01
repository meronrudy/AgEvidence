module Api
  module V1
    class StatementsController < BaseController
      def index
        require_scope!("statements:read")
        envelope(policy_scope(Artifact).order(artifact_code: :desc).map { |statement| serialize(statement) })
      end

      def show
        require_scope!("statements:read")
        statement = policy_scope(Artifact).find_by!(artifact_code: params[:id])
        envelope(serialize(statement).merge("verification" => statement.public_verification_payload))
      end

      private

      def serialize(statement)
        {
          "id" => statement.artifact_code,
          "scope" => statement.claim,
          "status" => statement.status,
          "issued" => statement.issued?,
          "issued_at" => statement.issued_at&.utc&.iso8601,
          "digest" => statement.digest,
          "profile_version" => statement.artifact.dig("program", "version") || statement.artifact.dig("profile", "version")
        }
      end
    end
  end
end
