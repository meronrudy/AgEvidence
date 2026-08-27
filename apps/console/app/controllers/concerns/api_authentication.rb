module ApiAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_api_key
  end

  private

  def authenticate_api_key
    token = request.headers["X-AgEvidence-API-Key"].presence ||
      request.authorization.to_s.delete_prefix("Bearer ").strip.presence
    @api_key = ApiKey.authenticate(token)
    return unauthorized_error unless @api_key

    @current_organization = @api_key.organization
  end
end
