class EvaluationsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @evaluations = current_organization.evaluations
      .includes(:program_profile, :project)
      .order(evaluated_at: :desc)
  end

  def show
    @evaluation = policy_scope(Evaluation).includes(:program_profile, :project).find_by!(evaluation_code: params[:code])
    @project = @evaluation.project
    authorize @project
    @determination = @project.determinations.find_by(program_profile: @evaluation.program_profile)
    @artifact = @project.artifact
    @gaps = @project.gaps.order(:severity, :gap_code)
  end
end
