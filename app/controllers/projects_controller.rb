class ProjectsController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell
  before_action :load_project, except: :index

  def index
    scoped_projects = policy_scope(Project)
    @jurisdictions = scoped_projects.distinct.order(:jurisdiction).pluck(:jurisdiction)
    @statuses = scoped_projects.distinct.order(:status).pluck(:status)
    @projects = scoped_projects.includes(:organization).order(last_activity_at: :desc)
    @projects = apply_project_filters(@projects)
  end

  def show
    authorize @project
    @activities = @project.activities.order(occurred_at: :desc).limit(5)
  end

  def evidence
    authorize @project
    @records = @project.evidence_records.order(received_at: :asc)
    @selected_record = @records.find_by(record_code: params[:selected]) || @records.first
  end

  def assessment
    authorize @project
    @gaps = @project.gaps.order(severity: :asc, gap_code: :asc)
  end

  def review
    authorize @project
    @reviews = @project.reviews.includes(:review_decisions).order(:review_code)
    @active_review = @reviews.find_by(review_code: params[:review]) || @reviews.first
    @decisions = @reviews.flat_map(&:review_decisions).sort_by(&:recorded_at).reverse
  end

  def create_review_decision
    authorize @project, :review_decision?
    review = @project.reviews.find_by!(review_code: params.require(:review_code))
    ReviewDecisionService.create!(
      review: review,
      decision: params.require(:decision),
      actor: current_user,
      rationale: params[:rationale],
      limitation: params[:limitation],
      metadata: audit_metadata
    )
    redirect_to review_project_path(@project.slug, review: review.review_code), notice: "Decision recorded."
  end

  def artifact
    @artifact = @project.artifact || raise(ActiveRecord::RecordNotFound)
    authorize @artifact
  end

  def issue_artifact
    artifact = @project.artifact || raise(ActiveRecord::RecordNotFound)
    authorize artifact, :issue?
    ArtifactIssuanceService.issue!(artifact: artifact, actor: current_user, metadata: audit_metadata)
    redirect_to artifact_project_path(@project.slug), notice: "Artifact issued."
  end

  def download_artifact
    artifact = @project.artifact || raise(ActiveRecord::RecordNotFound)
    authorize artifact, :download?
    send_data(
      JSON.pretty_generate(artifact.artifact),
      filename: "#{artifact.artifact_code}.json",
      type: "application/json"
    )
  end

  def download_bundle
    artifact = @project.artifact || raise(ActiveRecord::RecordNotFound)
    authorize artifact, :download?
    bundle = {
      project: @project.attributes.slice("slug", "project_code", "name", "jurisdiction", "program", "scope"),
      evidence: @project.evidence_records.order(:record_code).map { |r| { id: r.record_code, schema: r.schema_name, digest: r.digest } },
      artifact: artifact.artifact
    }
    send_data(JSON.pretty_generate(bundle), filename: "#{@project.slug}-bundle.json", type: "application/json")
  end

  def activity
    authorize @project
    @activities = (@project.activities.order(occurred_at: :desc) + @project.reviews.flat_map(&:review_decisions)).sort_by do |item|
      item.respond_to?(:recorded_at) ? item.recorded_at : item.occurred_at
    end.reverse
  end

  private

  def load_project
    @project = policy_scope(Project).includes(:organization).find_by!(slug: params[:slug])
  end

  def apply_project_filters(projects)
    if params[:q].present?
      q = "%#{params[:q].downcase}%"
      projects = projects.where("lower(projects.name) LIKE ? OR lower(projects.project_code) LIKE ? OR lower(projects.program) LIKE ?", q, q, q)
    end
    projects = projects.where(jurisdiction: params[:jurisdiction]) if params[:jurisdiction].present?
    projects = projects.where(status: params[:status]) if params[:status].present?
    projects = projects.joins(:organization).where(organizations: { name: params[:organization] }) if params[:organization].present?
    projects
  end
end
