class WebhookRetryService
  def self.retry!(delivery:, actor:, metadata: {})
    WebhookDelivery.transaction do
      delivery.retry!
      AuditEvent.log!(
        action: "webhook_delivery_retry_scheduled",
        actor: actor,
        organization: delivery.webhook_endpoint.organization,
        auditable: delivery,
        metadata: metadata.merge(delivery_code: delivery.delivery_code, attempt: delivery.attempt)
      )
      delivery
    end
  end
end
