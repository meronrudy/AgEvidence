class WebhookEndpoint < ApplicationRecord
  include JsonBacked

  belongs_to :organization, optional: true
  has_many :webhook_deliveries, dependent: :destroy

  json_field :events, default: []

  validates :endpoint_code, :url, :status, presence: true

  def last_delivery
    webhook_deliveries.order(delivered_at: :desc).first
  end
end
