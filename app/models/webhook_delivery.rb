class WebhookDelivery < ApplicationRecord
  include JsonBacked

  belongs_to :webhook_endpoint

  json_field :timeline, default: []
  json_field :response, default: {}

  validates :delivery_code, :attempt, :max_attempts, :status, :duration_ms, :delivered_at, presence: true

  def retry!
    update!(
      attempt: attempt + 1,
      delivered_at: Time.current,
      status: 202,
      duration_ms: 112,
      response: { "queued" => true, "message" => "Retry scheduled" }
    )
  end
end
