module V1
  class BaseController < ActionController::API
    include ApiAuthentication
    include ApiScopeAuthorization
    include ApiRequestLogging
    include ApiIdempotency

    before_action :set_request_start_time
    after_action :verify_authorized, except: :index
    after_action :store_idempotency_response, if: -> { request.post? || request.put? || request.patch? }

    def set_request_start_time
      @request_start_time = Time.current
    end

    def verify_authorized
      # Skip authorization check for index actions
      return if action_name == 'index'
      # Skip if no policy is defined
    end

    def store_idempotency_response
      return unless @api_key && request.headers['Idempotency-Key']
      
      response_body = response.body
      status = response.status
      
      ApiIdempotencyKey.create!(
        organization_id: @api_key.organization_id,
        idempotency_key: request.headers['Idempotency-Key'],
        http_method: request.request_method,
        request_path: request.path,
        response_json: response_body,
        response_status: status
      )
    rescue => e
      logger.error "Failed to store idempotency response: #{e.message}"
    end

    def render_error(code, message, status = :unprocessable_entity)
      render json: {
        error: {
          code: code,
          message: message
        }
      }, status: status
    end

    def unauthorized_error
      render json: {
        error: {
          code: 'unauthorized',
          message: 'Invalid or missing API key'
        }
      }, status: :unauthorized
    end

    def forbidden_error(message = 'Forbidden')
      render json: {
        error: {
          code: 'forbidden',
          message: message
        }
      }, status: :forbidden
    end

    def not_found_error(message = 'Resource not found')
      render json: {
        error: {
          code: 'not_found',
          message: message
        }
      }, status: :not_found
    end

    def unprocessable_entity_error(message = 'Unprocessable entity')
      render json: {
        error: {
          code: 'validation_error',
          message: message
        }
      }, status: :unprocessable_entity
    end

    def conflict_error(message = 'Conflict')
      render json: {
        error: {
          code: 'conflict',
          message: message
        }
      }, status: :conflict
    end

    def feature_unavailable_error(message = 'Feature not available')
      render json: {
        error: {
          code: 'feature_unavailable',
          message: message
        }
      }, status: :service_unavailable
    end
  end
end