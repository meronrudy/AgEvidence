class AppController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def overview
    @projects = policy_scope(Project).includes(:organization).order(readiness: :desc)
    @profile = ProgramProfile.find_by!(code: "AU")
    @critical_gap_count = @projects.sum(:critical_gaps)
    @projects_with_critical_gaps_count = @projects.where("critical_gaps > 0").count
    @open_review_count = Review.joins(:project).where(projects: { organization_id: current_organization.id }, state: "open").count
    @webhook_failure_count = WebhookDelivery.joins(webhook_endpoint: :organization).where(webhook_endpoints: { organization_id: current_organization.id }).where("webhook_deliveries.status >= 400").count
    @artifacts_ready_count = policy_scope(Artifact).where(issued: false).count
    @activities = Activity.joins(:project).where(projects: { organization_id: current_organization.id }).order(occurred_at: :desc).limit(6)
    @artifact = Artifact.joins(:project).where(projects: { organization_id: current_organization.id }).find_by!(artifact_code: "RA-AU-000184")
    @evidence_records = EvidenceRecord.joins(:project).where(projects: { organization_id: current_organization.id })
    @artifacts = policy_scope(Artifact)
    @system_chain = [
      {
        eyebrow: "Source evidence",
        title: "#{@evidence_records.where(record_type: "source_manifest").count} manifests",
        identifier: "#{@evidence_records.count} canonical records",
        status: "valid",
        meta: [
          ["Accepted", @evidence_records.where(status: "accepted").count, true],
          ["Source systems", @evidence_records.distinct.count(:source), true],
          ["Attention", @evidence_records.where(status: ["needs_mapping", "schema_error", "needs_review"]).count, true]
        ],
        basis_url: app_evidence_path
      },
      {
        eyebrow: "Program basis",
        title: @profile.name,
        identifier: "#{@profile.code} #{@profile.profile_version}",
        status: "valid",
        meta: [
          ["Requirements", @profile.requirements_count, true],
          ["Machine", @profile.machine_evaluable, true],
          ["Human", @profile.human_review, true]
        ],
        basis_url: app_program_australia_path
      },
      {
        eyebrow: "Reliance",
        title: "#{@artifacts.count} artifacts",
        identifier: @artifact.artifact_code,
        status: @artifact.issued? ? "issued" : "draft",
        meta: [
          ["Issued", @artifacts.where(issued: true).count, true],
          ["Awaiting issue", @artifacts.where(issued: false).count, true],
          ["Primary digest", @artifact.digest.first(18), true]
        ],
        basis_url: artifact_project_path(@artifact.project.slug)
      }
    ]
    @attention_items = [
      ["Material gaps", "#{@critical_gap_count} across #{@projects_with_critical_gaps_count} projects", app_program_evaluate_path(project: "dit-au-methane"), "material_gap"],
      ["Human review", "#{@open_review_count} decisions awaiting institutional judgment", app_reviews_path, "human_review"],
      ["Integration exceptions", "#{@webhook_failure_count} failed webhook deliveries", app_integrations_path, @webhook_failure_count.positive? ? "material_gap" : "valid"],
      ["Artifacts awaiting issue", "#{@artifacts_ready_count} reliance artifacts ready for signature", app_artifacts_path, "draft"]
    ]
  end

  def reviews
    @title = "Reviews"
    @description = "Human review work across projects, requirements, and reliance limitations."
    @rows = Review.joins(:project).where(projects: { organization_id: current_organization.id }).includes(:project, :review_decisions).order(:review_code)
    render :support_collection
  end

  def artifacts
    @title = "Artifacts"
    @description = "Reliance artifacts in draft, ready, and issued states."
    @rows = policy_scope(Artifact).includes(:project).order(:artifact_code)
    render :support_collection
  end

  def integrations
    @title = "Integrations"
    @description = "Connected evidence sources and ingestion health."
    @rows = Integration.where(organization: current_organization).order(:name)
    render :support_collection
  end

  def methodologies
    @title = "Methodologies"
    @description = "Versioned methodology and evidence policy profiles available to country programs."
    @rows = ProgramProfile.order(:code)
    render :support_collection
  end

  def verification
    @title = "Verification"
    @description = "Internal verification activity and public artifact checks."
    @rows = policy_scope(Artifact).order(:artifact_code)
    render :support_collection
  end

  def organization
    @title = "Organization"
    @description = "Organization context for the demo workspace."
    @organization = current_organization
    authorize @organization
    @memberships = @organization.organization_memberships.joins(:user).includes(:user, :role).order("users.email")
    @invitations = @organization.invitations.order(created_at: :desc).limit(10)
  end

  def settings
    @title = "Settings"
    @description = "Demo workspace settings."
    @settings = [
      ["Workspace", current_organization&.name],
      ["Environment", current_organization&.environment],
      ["Default jurisdiction", "Australia"],
      ["Signed in as", current_user.full_name]
    ]
  end

  def documentation
    @title = "Documentation"
    @description = "Developer and reviewer references for the demo."
    @docs = EvidenceSchema.order(:name)
  end
end
