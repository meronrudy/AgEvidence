class WebhookRetryJob < ApplicationJob
  queue_as :default

  def perform(delivery_id, actor_id = nil)
    delivery = WebhookDelivery.find(delivery_id)
    actor = User.find_by(id: actor_id)
    WebhookRetryService.retry!(delivery: delivery, actor: actor, metadata: { source: "job" })
  end
end
