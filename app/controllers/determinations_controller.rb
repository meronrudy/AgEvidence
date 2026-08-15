class DeterminationsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @determinations = policy_scope(Determination).includes(:program_profile, :project).order(published_at: :desc)
  end

  def show
    @determination = policy_scope(Determination).includes(:program_profile, :project).find_by!(determination_code: params[:code])
    @project = @determination.project
    authorize @project
    @evaluation = @determination.evaluation || @project.evaluations.find_by(program_profile: @determination.program_profile)
    @artifact = @project.artifact
    @activities = @project.activities.order(occurred_at: :desc).limit(5)
  end
end
