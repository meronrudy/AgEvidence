class DeveloperController < ApplicationController
  before_action :authenticate_app_user!
  before_action :use_app_shell

  def index
    @stats = {
      events_today: EvidenceRecord.joins(:project).where(projects: { organization_id: current_organization.id }).count,
      acceptance_rate: 92,
      schema_errors: EvidenceRecord.joins(:project).where(projects: { organization_id: current_organization.id }, status: "schema_error").count,
      webhooks_failing: WebhookDelivery.joins(:webhook_endpoint).where(webhook_endpoints: { organization_id: current_organization.id }).where("webhook_deliveries.status >= 400").count
    }
    @curl_example = <<~CURL
      curl https://api.agevidence.com/v1/integrations/events \\
        -H "Authorization: Bearer agev_live_..." \\
        -H "Content-Type: application/json" \\
        -d '{"schema":"feed_event.v1","project":"PRJ-AU-00041"}'
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
end
