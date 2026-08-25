class StatementSharesController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def create
    statement = policy_scope(Artifact).find_by!(artifact_code: params[:code])
    authorize statement, :share?
    share = statement.statement_shares.create!(
      created_by_user: current_user,
      access_level: share_params[:access_level].presence || "statement_and_summary",
      expires_at: Time.current + expires_in_days.days
    )
    redirect_to app_statement_path(statement.artifact_code), notice: "Share link created: #{shared_statement_url(share.token)}"
  end

  def destroy
    statement = policy_scope(Artifact).find_by!(artifact_code: params[:code])
    authorize statement, :share?
    share = statement.statement_shares.find(params[:share_id])
    share.revoke!
    redirect_to app_statement_path(statement.artifact_code), notice: "Share link revoked."
  end

  private

  def share_params
    params.fetch(:statement_share, {}).permit(:access_level, :expires_in_days)
  end

  def expires_in_days
    days = share_params[:expires_in_days].to_i
    days.positive? ? days : 30
  end
end
