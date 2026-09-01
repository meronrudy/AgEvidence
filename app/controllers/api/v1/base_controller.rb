module Api
  module V1
    class BaseController < ActionController::API
      include Pundit::Authorization

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
      rescue_from Pundit::NotAuthorizedError, with: :forbidden
      rescue_from ArgumentError, with: :bad_request

      before_action :authenticate_api_key!
      around_action :record_api_log

      attr_reader :current_api_key, :current_organization

      private

      def authenticate_api_key!
        token = request.authorization.to_s.delete_prefix("Bearer ").strip
        @current_api_key = ApiKey.authenticate(token)
        return unauthorized unless @current_api_key

        @current_api_key.touch(:last_used_at)
        @current_organization = @current_api_key.organization
        return unauthorized unless @current_organization

        Current.api_key = @current_api_key
        Current.organization = @current_organization
        Current.product_pack = PortfolioProducts::Registry.fetch_for_organization(@current_organization)
      end

      def api_actor
        nil
      end

      def audit_metadata
        {
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          request_id: request.request_id,
          api_key_code: current_api_key&.key_code
        }
      end

      def policy_scope(scope)
        super(scope)
      end

      def pundit_user
        ApiPrincipal.new(current_api_key)
      end

      def envelope(data, status: :ok)
        render json: {
          contract_version: "api-envelope.v1",
          request_id: request.request_id,
          data: data
        }, status: status
      end

      def error_envelope(code:, message:, status:)
        render json: {
          contract_version: "error-response.v0",
          request_id: request.request_id,
          error: {
            code: code,
            message: message
          }
        }, status: status
      end

      def unauthorized
        error_envelope(code: "unauthorized", message: "A valid API key is required.", status: :unauthorized)
      end

      def forbidden
        error_envelope(code: "forbidden", message: "The API key is not authorized for this resource.", status: :forbidden)
      end

      def require_scope!(scope)
        return if current_api_key&.allows?(scope)

        raise Pundit::NotAuthorizedError, "missing scope #{scope}"
      end

      def not_found
        error_envelope(code: "not_found", message: "The requested resource was not found.", status: :not_found)
      end

      def record_invalid(error)
        error_envelope(code: "validation_failed", message: error.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end

      def bad_request(error)
        error_envelope(code: "bad_request", message: error.message, status: :bad_request)
      end

      def record_api_log
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield
      ensure
        if current_api_key
          duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
          ApiLog.create!(
            organization: current_organization,
            log_code: "LOG-#{SecureRandom.hex(5).upcase}",
            method: request.request_method,
            endpoint: request.path,
            status: response.status,
            duration_ms: duration_ms,
            occurred_at: Time.current,
            operation_id: request.request_id,
            request: redacted_request_summary,
            response: { "status" => response.status },
            trace: [{ "step" => "api_request", "ok" => response.status < 500 }]
          )
        end
        Current.reset
      end

      def redacted_request_summary
        params.to_unsafe_h.except("controller", "action", "password", "token", "authorization")
      end
    end
  end
end
