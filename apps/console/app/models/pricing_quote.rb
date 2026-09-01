class PricingQuote < ApplicationRecord
  include JsonBacked

  STATUSES = %w[draft quoted sent revised accepted rejected expired withdrawn].freeze

  belongs_to :organization
  belongs_to :project, optional: true
  belongs_to :price_version
  belongs_to :pricing_experiment, optional: true
  has_one :artifact_order, dependent: :nullify
  has_many :commercial_outcomes, dependent: :nullify

  json_field :commercial_terms, default: {}
  json_field :breakdown, default: []

  before_validation :assign_quote_id
  before_validation :copy_price_version_fields

  validates :quote_id, :product_code, :product_version, :currency, :pricing_unit, :status, :quoted_at, presence: true
  validates :quote_id, uniqueness: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :list_price_cents, :offered_price_cents, :discount_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :tenant_matches_project_and_price_version
  validate :pricing_experiment_matches_quote

  def amount_cents
    offered_price_cents
  end

  def pricing_version
    price_version.product_version
  end

  def accept!
    update!(status: "accepted", accepted_at: Time.current)
  end

  private

  def assign_quote_id
    self.quote_id ||= "QUOTE-#{SecureRandom.hex(5).upcase}"
  end

  def copy_price_version_fields
    return unless price_version

    self.organization ||= price_version.organization
    self.product_code ||= price_version.product_code
    self.product_version ||= price_version.product_version
    self.currency ||= price_version.currency
    self.pricing_unit ||= price_version.pricing_unit
    self.list_price_cents = price_version.list_price_cents if list_price_cents.nil?
    self.offered_price_cents = list_price_cents if offered_price_cents.nil?
    self.discount_cents = [list_price_cents.to_i - offered_price_cents.to_i, 0].max if discount_cents.nil? && offered_price_cents
    self.quoted_at ||= Time.current
    self.expires_at ||= 30.days.from_now
  end

  def tenant_matches_project_and_price_version
    if project.present? && organization.present? && project.organization_id != organization_id
      errors.add(:project, "must belong to the quote organization")
    end

    if price_version.present? && organization.present? && price_version.organization_id != organization_id
      errors.add(:price_version, "must belong to the quote organization")
    end
  end

  def pricing_experiment_matches_quote
    return if pricing_experiment.blank?

    if pricing_experiment.organization_id != organization_id
      errors.add(:pricing_experiment, "must belong to the quote organization")
    end

    if pricing_experiment.product_code != product_code
      errors.add(:pricing_experiment, "must target the quoted product")
    end
  end
end
