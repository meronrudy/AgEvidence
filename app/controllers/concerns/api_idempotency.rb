module ApiIdempotency
  module ClassMethods
    def included(base)
      base.before_action :check_idempotency
    end
  end

  private
    def check_idempotency
      idempotency_key = request.headers['Idempotency-Key']
      return unless idempotency_key
      
      organization_id = @api_key&.organization_id
      return unless organization_id
      
      # Lookup key: organization_id + Idempotency-Key + HTTP method + request path
      existing = ApiIdempotencyKey.find_by(
        organization_id: organization_id,
        idempotency_key: idempotency_key,
        http_method: request.request_method,
        request_path: request.path
      )
      
      if existing
        # Replay-safe behavior: return existing response
        render json: existing.response_json, status: existing.response_status
      end
    end

    def store_idempotency_response(response, status)
      idempotency_key = request.headers['Idempotency-Key']
      return unless idempotency_key
      
      organization_id = @api_key&.organization_id
      return unless organization_id
      
      ApiIdempotencyKey.create!(
        organization_id: organization_id,
        idempotency_key: idempotency_key,
        http_method: request.request_method,
        request_path: request.path,
        response_json: response,
        response_status: status
      )
    end
  end