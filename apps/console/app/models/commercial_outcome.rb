class CommercialOutcome < ApplicationRecord
  include JsonBacked

  STATES = %w[draft quoted won lost abandoned renewed expanded churned no_decision withdrawn].freeze
  LOSS_REASONS = %w[price no_budget wrong_unit procurement feature_gap no_urgency bundled_elsewhere].freeze

  belongs_to :organization
  belongs_to :pricing_quote, optional: true
  belongs_to :artifact_order, optional: true
  belongs_to :pricing_experiment, optional: true

  json_field :metadata, default: {}

  validates :product_code, :state, :occurred_at, presence: true
  validates :state, inclusion: { in: STATES }
  validates :reason, inclusion: { in: LOSS_REASONS }, allow_blank: true
  validate :tenant_matches_related_records

  private

  def tenant_matches_related_records
    [pricing_quote, artifact_order, pricing_experiment].compact.each do |record|
      next if record.organization_id == organization_id

      errors.add(record.model_name.singular, "must belong to the outcome organization")
    end
  end
end
