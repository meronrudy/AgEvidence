class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  before_action :resolve_domain_organization
  around_action :reset_current_context

  helper_method :current_organization, :current_membership, :current_role,
    :current_product_pack, :current_brand

  private

  def reset_current_context
    Current.reset
    yield
  ensure
    Current.reset
  end

  def resolve_domain_organization
    return unless defined?(DomainMapping) && ActiveRecord::Base.connection.data_source_exists?("domain_mappings")

    hostname = request.host.to_s.downcase
    mapping = DomainMapping.verified.find_by(hostname: hostname)
    @domain_organization = mapping&.organization

    if mapping.blank? && DomainMapping.exists? && unknown_custom_domain?(hostname)
      not_found
    end
  end

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
    if @domain_organization
      @current_membership = memberships.find_by(organization_id: @domain_organization.id)
    end
    @current_membership ||= memberships.find_by(organization_id: session[:organization_id]) if session[:organization_id].present?
    @current_membership ||= memberships.first
    session[:organization_id] = @current_membership.organization_id if @current_membership
    @current_organization = @current_membership&.organization
    Current.user = current_user
    Current.organization = @current_organization
    Current.product_pack = current_product_pack if @current_organization
    @current_organization
  end

  def current_membership
    current_organization unless defined?(@current_membership)
    @current_membership
  end

  def current_role
    current_membership&.role
  end

  def current_product_pack
    return @current_product_pack if defined?(@current_product_pack)

    @current_product_pack = PortfolioProducts::Registry.fetch_for_organization(current_organization)
    Current.product_pack = @current_product_pack
  end

  def current_brand
    @current_brand ||= BrandResolver.resolve(organization: current_organization)
  end

  def require_product_capability!(capability)
    return if current_product_pack.enabled?(capability)

    raise Pundit::NotAuthorizedError, "product capability unavailable: #{capability}"
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

  def unknown_custom_domain?(hostname)
    return false if hostname.in?(%w[www.example.com example.com test.host localhost 127.0.0.1 0.0.0.0])
    return false if hostname.end_with?(".test")

    true
  end
end
