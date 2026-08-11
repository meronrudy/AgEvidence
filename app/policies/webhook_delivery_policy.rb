class WebhookDeliveryPolicy < ApplicationPolicy
  def retry?
    has_any_role?(:org_admin, :operator)
  end

  private

  def organization
    record.webhook_endpoint.organization
  end
end
