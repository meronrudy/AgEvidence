class AppController < ApplicationController
  CANONICAL_PROFILE_CODE = "AU_METHANE_INTERVENTION_V1".freeze

  before_action :authenticate_app_user!
  before_action :use_app_shell

  def overview
    @project = current_organization.projects.find_by!(slug: "dit-production")
    @profile = ProgramProfile.find_by!(code: CANONICAL_PROFILE_CODE)
    @open_review_count = current_organization.reviews.open.count
    @webhook_failure_count = WebhookDelivery.joins(webhook_endpoint: :organization).where(webhook_endpoints: { organization_id: current_organization.id }).where("webhook_deliveries.status >= 400").count
    @activities = current_organization.activities.order(occurred_at: :desc).limit(8)
    @statement = current_organization.artifacts.find_by!(artifact_code: "AE-AU-000184")
    @evidence_records = current_organization.evidence_records
    @statements = policy_scope(Artifact)
    @plane_metrics = {
      ingestion: [
        ["1,267", "records today"],
        ["98.7%", "accepted"],
        ["12", "schema / mapping exceptions"]
      ],
      evaluation: [
        ["1", "active profile"],
        [@profile.requirements_count.to_s, "requirements"],
        ["2", "requiring attention"]
      ],
      governance: [
        ["2", "reviews awaiting decision"],
        ["1", "qualification"]
      ],
      statements: [
        ["4", "ready"],
        ["11", "issued"]
      ]
    }
    @operational_health = [
      ["uDOSE production", "HEALTHY", "success"],
      ["AU Methane profile", "CURRENT", "success"],
      ["API", "HEALTHY", "success"],
      ["Webhooks", "1 RETRYING", "warning"],
      ["Integrity", "VALID", "success"]
    ]
    @attention_items = [
      ["Machine gap", "AE-METH-008 calibration evidence requires attention", app_gaps_path, "material_gap"],
      ["Human review", "#{@open_review_count} decisions awaiting institutional judgment", app_reviews_path, "human_review"],
      ["Integration exceptions", "#{@webhook_failure_count} failed webhook deliveries", app_integrations_path, @webhook_failure_count.positive? ? "material_gap" : "valid"],
      ["Statements ready", "4 Evidence Statements ready for issue", app_statements_path, "draft"]
    ]
  end

  def reviews
    @title = "Reviews"
    @description = "Human review work across projects, requirements, and reliance limitations."
    @rows = Review.joins(:project).where(projects: { organization_id: current_organization.id }).includes(:project, :review_decisions).order(:review_code)
    render :support_collection
  end

  def artifacts
    @title = "Evidence Statements"
    @description = "Bounded statements in draft, ready, issued, superseded, and revoked states."
    @rows = policy_scope(Artifact).includes(:project).order(:artifact_code)
    render :support_collection
  end

  def integrations
    @title = "Integrations"
    @description = "Connected production sources, primitive coverage, and ingestion health."
    @rows = Integration.where(organization: current_organization).order(:name)
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
end
