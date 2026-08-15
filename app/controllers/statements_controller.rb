class StatementsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @statements = policy_scope(Artifact)
      .includes(:project, :statement_shares)
      .order(issued: :asc, artifact_code: :desc)
  end

  def show
    @statement = policy_scope(Artifact).includes(:project, :statement_shares).find_by!(artifact_code: params[:code])
    authorize @statement, :show?
    @project = @statement.project
    @evaluation = @project.evaluations.order(evaluated_at: :desc).first
    @determination = @project.determinations.order(published_at: :desc).first
    @shares = @statement.statement_shares.order(created_at: :desc)
  end

  def issue
    statement = policy_scope(Artifact).find_by!(artifact_code: params[:code])
    authorize statement, :issue?
    EvidencePlane::IssueStatement.call(statement: statement, actor: current_user, metadata: audit_metadata)
    redirect_to app_statement_path(statement.artifact_code), notice: "Evidence Statement issued."
  rescue ArgumentError, ActiveRecord::RecordInvalid => e
    redirect_to app_statement_path(params[:code]), alert: e.message
  end
end
