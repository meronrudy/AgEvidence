module Api
  module V1
    class ArtifactsController < BaseController
      def show
        require_scope!("artifacts:read")
        artifact = policy_scope(Artifact).find_by!(artifact_code: params[:artifact_code])
        authorize artifact
        envelope(artifact.public_verification_payload)
      end

      def verify
        require_scope!("artifacts:verify")
        artifact = policy_scope(Artifact).find_by!(artifact_code: params[:artifact_code])
        authorize artifact
        result = Trust::Verifier.record_artifact!(
          artifact: artifact,
          actor: api_actor,
          metadata: audit_metadata
        )
        envelope(
          artifact.public_verification_payload.merge(
            "verifier_result_code" => result.result_code,
            "verifier_result_status" => result.status
          )
        )
      end
    end
  end
end
