module ApiAuthentication
  module ClassMethods
    def included(base)
      base.before_action :authenticate_api_key
    end
  end

  private
    def authenticate_api_key
      token = request.headers['X-AgEvidence-API-Key']
      @api_key = ApiKey.authenticate(token)
      return unauthorized_error unless @api_key
      @current_organization = @api_key.organization
    end
  end
end

class ApiKey
  def self.authenticate(token)
    ApiKey.find_by(api_key: token)&.tap do |key|
      return key if key&.active?
    end
    nil
  end
end