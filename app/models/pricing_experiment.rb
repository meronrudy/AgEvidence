class PricingExperiment < ApplicationRecord
  include JsonBacked

  STATUSES = %w[draft active paused completed archived].freeze

  belongs_to :organization
  belongs_to :price_version, optional: true
  has_many :pricing_quotes, dependent: :nullify
  has_many :commercial_outcomes, dependent: :nullify

  json_field :metadata, default: {}

  validates :product_code, :product_version, :name, :pricing_unit, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :price_version_matches_experiment

  private

  def price_version_matches_experiment
    return if price_version.blank?

    errors.add(:price_version, "must belong to the same organization") if price_version.organization_id != organization_id
    errors.add(:price_version, "must price the same product") if price_version.product_code != product_code
  end
end
