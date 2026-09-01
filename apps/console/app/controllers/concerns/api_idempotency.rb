module ApiIdempotency
  extend ActiveSupport::Concern

  included do
    before_action :check_idempotency
  end

  private

  def check_idempotency
    idempotency_key = request.headers["Idempotency-Key"]
    return unless idempotency_key

    organization_id = @api_key&.organization_id
    return unless organization_id

    existing = ApiIdempotencyKey.find_by(
      organization_id: organization_id,
      key: idempotency_key,
      method: request.request_method,
      path: request.path
    )

    render json: existing.response_json, status: existing.status if existing
  end

  def store_idempotency_response(response_body, status)
    idempotency_key = request.headers["Idempotency-Key"]
    return unless idempotency_key

    organization_id = @api_key&.organization_id
    return unless organization_id

    ApiIdempotencyKey.create!(
      organization_id: organization_id,
      key: idempotency_key,
      method: request.request_method,
      path: request.path,
      response_json: response_body,
      status: status
    )
  end
end
