class OrganizationsController < ApplicationController
  before_action :authenticate_app_user!

  def switch
    membership = current_user.organization_memberships.active.find_by!(organization_id: params.require(:organization_id))
    session[:organization_id] = membership.organization_id
    redirect_back fallback_location: app_home_path, notice: "Organization switched."
  end
end
