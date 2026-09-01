class CommercialEvent < ApplicationRecord
  include JsonBacked

  EVENT_TYPES = %w[
    product_viewed
    quote_created
    quote_sent
    quote_revised
    quote_accepted
    quote_rejected
    order_created
    payment_recorded
    artifact_issued
    artifact_downloaded
    reliance_recorded
    renewal_created
    expansion_created
    subscription_cancelled
  ].freeze

  belongs_to :organization
  belongs_to :project, optional: true
  belongs_to :pricing_quote, optional: true
  belongs_to :artifact_order, optional: true

  json_field :value, default: {}

  validates :event_type, :occurred_at, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :tenant_matches_related_records

  def exportable_value
    policy = PortfolioProducts::Registry.fetch_for_organization(organization).telemetry_policy
    policy.filter(value)
  end

  private

  def tenant_matches_related_records
    [project, pricing_quote, artifact_order].compact.each do |record|
      next if record.organization_id == organization_id

      errors.add(record.model_name.singular, "must belong to the event organization")
    end
  end
end
