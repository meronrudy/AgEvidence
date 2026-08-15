module Api
  module V1
    class RelianceEventsController < BaseController
      def create
        require_scope!("reliance_events:create")
        artifact = policy_scope(Artifact).find_by!(artifact_code: params[:artifact_code])
        authorize artifact, :download?
        reliance_event = RelianceEventRecorder.record!(
          artifact: artifact,
          actor: api_actor,
          attributes: reliance_event_params,
          metadata: audit_metadata
        )
        envelope(serialize_reliance_event(reliance_event), status: :created)
      end

      private

      def reliance_event_params
        event_params = params[:reliance_event].presence || params
        ActionController::Parameters.new(event_params.to_unsafe_h).permit(
          :relying_party,
          :relying_party_role,
          :reliance_kind,
          :status,
          :occurred_at,
          basis: {},
          metadata: {}
        )
      end

      def serialize_reliance_event(reliance_event)
        {
          "contract_version" => "reliance-event.v0",
          "event_code" => reliance_event.event_code,
          "artifact_code" => reliance_event.artifact.artifact_code,
          "relying_party" => reliance_event.relying_party,
          "reliance_kind" => reliance_event.reliance_kind,
          "status" => reliance_event.status,
          "occurred_at" => reliance_event.occurred_at.utc.iso8601
        }
      end
    end
  end
end
