module ApiScopeAuthorization
  module ClassMethods
    def included(base)
      base.before_action :require_scope
    end
  end

  private
    def require_scope
      # Extract required scope from controller action mapping
      required_scope = scope_for_action
      return unless required_scope
      
      unless @api_key&.has_scope?(required_scope)
        render json: {
          error: {
            code: "insufficient_scope",
            message: "Insufficient scope for this operation"
          }
        }, status: :forbidden
      end
    end

    def scope_for_action
      # Default mapping - can be overridden in controllers
      case action_name.to_sym
      when :create
        "#{controller_name.singularize}:create"
      when :show, :index
        "#{controller_name.singularize}:read"
      when :update, :patch
        "#{controller_name.singularize}:update"
      when :destroy
        "#{controller_name.singularize}:delete"
      else
        nil
      end
    end
end