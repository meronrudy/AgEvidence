class DeveloperController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell
  before_action :require_developer_capability

  def index
    @stats = {
      events_today: 1267,
      acceptance_rate: 98.7,
      schema_errors: 12,
      webhooks_failing: WebhookDelivery.joins(:webhook_endpoint).where(webhook_endpoints: { organization_id: current_organization.id }).where("webhook_deliveries.status >= 400").count
    }
    @curl_example = <<~CURL
      curl https://api.agevidence.com/api/v1/evidence \\
        -H "Authorization: Bearer agev_live_..." \\
        -H "Content-Type: application/json" \\
        -H "Idempotency-Key: evt-99231" \\
        -d '{"type":"InterventionEvent","schema":"agevidence.intervention_event.v1","external_id":"dit-evt-99231","subject":{"cohort_id":"C-18"},"intervention":{"product_lot":"PL-443","delivery":"dose_record"}}'
    CURL
  end

  def logs
    @logs = ApiLog.where(organization: current_organization).order(occurred_at: :desc)
    @selected_log = @logs.find_by(log_code: params[:selected]) || @logs.first
  end

  def webhooks
    @endpoints = WebhookEndpoint.where(organization: current_organization).includes(:webhook_deliveries).order(:url)
    @selected_delivery = WebhookDelivery.joins(:webhook_endpoint).where(webhook_endpoints: { organization_id: current_organization.id }).find_by(delivery_code: params[:delivery]) ||
                         @endpoints.flat_map(&:webhook_deliveries).max_by(&:delivered_at)
    @selected_endpoint = @selected_delivery&.webhook_endpoint || @endpoints.first
  end

  def retry_webhook
    delivery = WebhookDelivery.joins(:webhook_endpoint).where(webhook_endpoints: { organization_id: current_organization.id }).find_by!(delivery_code: params[:id])
    authorize delivery, :retry?
    WebhookRetryService.retry!(delivery: delivery, actor: current_user, metadata: audit_metadata)
    redirect_to app_developer_webhooks_path(delivery: delivery.delivery_code), notice: "Delivery retry scheduled."
  end

  def keys
    @keys = ApiKey.where(organization: current_organization).order(:name)
  end

  def schemas
    @schemas = EvidenceSchema.order(:name)
  end

  def openapi
    @endpoints = ApiLog.where(organization: current_organization).order(:endpoint).pluck(:method, :endpoint).uniq
  end

  private

  def require_developer_capability
    capability = action_name == "webhooks" || action_name == "retry_webhook" ? "webhooks" : "developer_api"
    require_product_capability!(capability)
  end
end
