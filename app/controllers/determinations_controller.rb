class DeterminationsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    project_names = policy_scope(Project).select(:name)
    @determinations = Determination.includes(:program_profile)
                                   .where(project_name: project_names)
                                   .order(published_at: :desc)
    @projects_by_name = policy_scope(Project).where(name: @determinations.map(&:project_name)).index_by(&:name)
  end

  def show
    @determination = Determination.includes(:program_profile).find_by!(determination_code: params[:code])
    @project = policy_scope(Project).find_by!(name: @determination.project_name)
    authorize @project
    @evaluation = Evaluation.find_by(program_profile: @determination.program_profile, project_name: @project.name)
    @artifact = @project.artifact
    @activities = @project.activities.order(occurred_at: :desc).limit(5)
  end
end
