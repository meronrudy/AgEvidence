class ProgramsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell
  before_action :load_australia_profile, only: [
    :australia, :australia_requirements, :australia_profiles, :australia_versions,
    :australia_evaluations, :australia_determinations
  ]

  def index
    @profiles = ProgramProfile.order(:code)
    @profiles = @profiles.where(status: params[:status]) if params[:status].present?
    @profiles = @profiles.where(code: params[:jurisdiction]) if params[:jurisdiction].present?
    if params[:q].present?
      q = "%#{params[:q].downcase}%"
      @profiles = @profiles.where("lower(name) LIKE ? OR lower(code) LIKE ? OR lower(status) LIKE ?", q, q, q)
    end
  end

  def requirements
    @requirements = Requirement.includes(:program_profile).order(:requirement_code)
  end

  def profiles
    @profiles = ProgramProfile.order(:code)
  end

  def evaluate
    @project_options = policy_scope(Project).order(:name)
    @project = @project_options.find_by(slug: params[:project]) || @project_options.find_by!(slug: "dit-au-methane")
    @profile = ProgramProfile.find_by!(code: "AU")
    @gaps = @project.gaps.order(:gap_code)
  end

  def compare
    @profile = ProgramProfile.find_by!(code: "AU")
    @comparison = @profile.comparison
    @selected_codes = Array(params[:programs].presence || @comparison.fetch("columns").map { |c| c.fetch("code") })
  end

  def australia
  end

  def australia_requirements
    @requirements = @profile.requirements.order(:requirement_code)
  end

  def australia_profiles
    @profiles = ProgramProfile.order(:code)
  end

  def australia_versions
  end

  def australia_evaluations
    @evaluations = @profile.evaluations.order(evaluated_at: :desc)
  end

  def australia_determinations
    @determinations = @profile.determinations.order(published_at: :desc)
  end

  private

  def load_australia_profile
    @profile = ProgramProfile.find_by!(code: "AU")
  end
end
