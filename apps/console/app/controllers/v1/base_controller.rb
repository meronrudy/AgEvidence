module V1
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :not_found_error
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid_error
    rescue_from KeyError, ArgumentError, with: :bad_request_error

    before_action :authenticate_api_key!
    around_action :record_api_log

    attr_reader :current_api_key, :current_organization

    private

    def authenticate_api_key!
      token = request.authorization.to_s.delete_prefix("Bearer ").strip
      token = request.headers["X-AgEvidence-API-Key"].to_s.strip if token.blank?
      @current_api_key = ApiKey.authenticate(token)
      return render_error("unauthorized", "A valid API key is required.", :unauthorized) unless @current_api_key

      @current_api_key.touch(:last_used_at)
      @current_organization = @current_api_key.organization
      return render_error("unauthorized", "The API key is not attached to an organization.", :unauthorized) unless @current_organization

      Current.api_key = @current_api_key
      Current.organization = @current_organization
      Current.product_pack = current_product_pack
    end

    def current_product_pack
      @current_product_pack ||= PortfolioProducts::Registry.fetch_for_organization(current_organization)
    end

    def require_scope!(scope)
      return if current_api_key&.allows?(scope)

      render_error("insufficient_scope", "Missing required scope: #{scope}", :forbidden)
    end

    def require_product_capability!(capability)
      return if current_product_pack.enabled?(capability)

      render_error("feature_unavailable", "Feature not available for this product pack.", :service_unavailable)
    end

    def render_error(code, message, status = :unprocessable_entity)
      render json: {
        error: {
          code: code,
          message: message
        }
      }, status: status
    end

    def not_found_error
      render_error("not_found", "Resource not found.", :not_found)
    end

    def record_invalid_error(error)
      render_error("validation_failed", error.record.errors.full_messages.to_sentence, :unprocessable_entity)
    end

    def bad_request_error(error)
      render_error("bad_request", error.message, :bad_request)
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
          request: params.to_unsafe_h.except("controller", "action", "password", "token", "authorization"),
          response: { "status" => response.status },
          trace: [{ "step" => "v1_api_request", "ok" => response.status < 500 }]
        )
      end
      Current.reset
    end
  end
end
