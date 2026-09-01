class InvitationsController < ApplicationController
  before_action :authenticate_app_user!, only: :create

  def show
    @invitation = Invitation.find_by!(token: params[:token])
    render status: (@invitation.pending? ? :ok : :gone)
  end

  def accept
    @invitation = Invitation.find_by!(token: params[:token])
    return render(:show, status: :gone) unless @invitation.pending?

    user = User.find_or_initialize_by(email: @invitation.email.downcase)
    user.assign_attributes(user_params.merge(provider: "email", status: "active"))
    user.password = params.require(:user).require(:password)
    user.password_confirmation = params.require(:user).require(:password_confirmation)
    user.confirmed_at ||= Time.current
    user.save!

    membership = @invitation.accept!(user)
    sign_in user
    session[:organization_id] = membership.organization_id

    AuditEvent.log!(
      action: "invitation_accepted",
      actor: user,
      organization: membership.organization,
      auditable: @invitation,
      metadata: audit_metadata
    )

    redirect_to app_home_path, notice: "Invitation accepted."
  rescue ActiveRecord::RecordInvalid => error
    @error = error.record.errors.full_messages.to_sentence
    render :show, status: :unprocessable_entity
  end

  def create
    authorize current_organization, :update?

    invitation = InvitationService.create!(
      organization: current_organization,
      email: params.require(:email),
      role_name: params.require(:role),
      invited_by: current_user,
      metadata: audit_metadata
    )

    redirect_to app_organization_path, notice: "Invitation created for #{invitation.email}."
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name)
  end
end
