module ApiScopeAuthorization
  extend ActiveSupport::Concern

  included do
    before_action :require_scope
  end

  private

  def require_scope
    required_scope = scope_for_action
    return unless required_scope
    return if @api_key&.allows?(required_scope)

    render json: {
      error: {
        code: "insufficient_scope",
        message: "Insufficient scope for this operation"
      }
    }, status: :forbidden
  end

  def scope_for_action
    case action_name.to_sym
    when :create
      "#{controller_name.singularize}:create"
    when :show, :index
      "#{controller_name.singularize}:read"
    when :update, :patch
      "#{controller_name.singularize}:update"
    when :destroy
      "#{controller_name.singularize}:delete"
    end
  end
end
