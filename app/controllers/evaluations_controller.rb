class EvaluationsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def show
    @evaluation = Evaluation.includes(:program_profile).find_by!(evaluation_code: params[:code])
    @project = policy_scope(Project).find_by!(name: @evaluation.project_name)
    authorize @project
    @determination = Determination.find_by(program_profile: @evaluation.program_profile, project_name: @project.name)
    @artifact = @project.artifact
    @gaps = @project.gaps.order(:severity, :gap_code)
  end
end
