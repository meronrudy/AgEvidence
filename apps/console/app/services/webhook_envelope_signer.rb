class WebhookEnvelopeSigner
  def self.build(event_name:, organization:, payload:, secret:, key_id:, occurred_at: Time.current)
    IntegrationEventSigner.build(
      event_name: event_name,
      organization: organization,
      payload: payload,
      secret: secret,
      key_id: key_id,
      occurred_at: occurred_at
    )
  end
end
