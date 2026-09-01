class PriceVersion < ApplicationRecord
  include JsonBacked

  STATUSES = %w[draft active retired].freeze

  belongs_to :organization
  has_many :pricing_quotes, dependent: :restrict_with_exception
  has_many :pricing_experiments, dependent: :nullify

  json_field :pricing_formula, :metadata, default: {}

  validates :product_code, :product_version, :currency, :pricing_unit, :effective_from, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :list_price_cents, :minimum_price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :product_is_enabled_for_organization
  validate :pricing_unit_is_allowed_for_product
  validate :effective_window_is_ordered

  scope :active, -> { where(status: "active").where("effective_from <= ?", Time.current).where("effective_to IS NULL OR effective_to > ?", Time.current) }

  def quote_only?
    list_price_cents.blank?
  end

  private

  def pack
    @pack ||= PortfolioProducts::Registry.fetch_for_organization(organization)
  end

  def product
    @product ||= pack.catalog.product(product_code)
  end

  def product_is_enabled_for_organization
    return if organization.blank? || product.present?

    errors.add(:product_code, "is not enabled for the organization product pack")
  end

  def pricing_unit_is_allowed_for_product
    return if product.blank? || product.pricing_units.include?(pricing_unit)

    errors.add(:pricing_unit, "is not allowed for #{product_code}")
  end

  def effective_window_is_ordered
    return if effective_to.blank? || effective_from.blank? || effective_to > effective_from

    errors.add(:effective_to, "must be after effective_from")
  end
end
