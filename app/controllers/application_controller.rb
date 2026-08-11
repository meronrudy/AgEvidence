class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  helper_method :current_organization, :current_membership, :current_role

  private

  def use_app_shell
    @app_shell = true
  end

  def authenticate_app_user!
    authenticate_user!
    return if current_organization

    redirect_to root_path, alert: "Your account does not have an active organization membership."
  end

  def current_organization
    return @current_organization if defined?(@current_organization)
    return @current_organization = nil unless user_signed_in?

    memberships = current_user.organization_memberships.active.includes(:organization, :role)
    @current_membership = memberships.find_by(organization_id: session[:organization_id]) if session[:organization_id].present?
    @current_membership ||= memberships.first
    session[:organization_id] = @current_membership.organization_id if @current_membership
    @current_organization = @current_membership&.organization
  end

  def current_membership
    current_organization unless defined?(@current_membership)
    @current_membership
  end

  def current_role
    current_membership&.role
  end

  def audit_metadata
    {
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_id: request.request_id
    }
  end

  def not_found
    render "shared/not_found", status: :not_found
  end

  def forbidden
    render "shared/not_found", status: :forbidden
  end
end
