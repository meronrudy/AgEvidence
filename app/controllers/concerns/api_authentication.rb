module ApiAuthentication
  extend ActiveSupport::Concern
  included do
    before_action :authenticate_api_key!
  end
  private
  def authenticate_api_key!
    token = request.authorization.to_s.delete_prefix("Bearer ").strip
    if token.blank?
      render_error(
        "unauthorized",
        "A valid API key is required.",
        :unauthorized
      )
      return
    end
    @current_api_key = ApiKey.authenticate(token)
    unless @current_api_key
      render_error(
        "unauthorized",
        "A valid API key is required.",
        :unauthorized
      )
      return
    end
    @current_organization = @current_api_key.organization
    unless @current_organization
      render_error(
        "unauthorized",
        "The API key is not attached to an organization.",
        :unauthorized
      )
      return
    end
    @current_api_key.touch(:last_used_at)
    Current.api_key = @current_api_key
    Current.organization = @current_organization
    Current.product_pack = PortfolioProducts::Registry.fetch_for_organization(@current_organization)
  end
end
