class ArtifactOrder < ApplicationRecord
  include JsonBacked

  STATUSES = %w[created checkout_pending checkout_completed fulfilled cancelled].freeze

  belongs_to :organization
  belongs_to :project, optional: true
  belongs_to :pricing_quote, optional: true
  has_many :commercial_events, dependent: :nullify
  has_many :commercial_outcomes, dependent: :nullify

  json_field :metadata, default: {}

  before_validation :assign_order_id
  before_validation :copy_quote_fields

  validates :order_id, :product_code, :status, presence: true
  validates :order_id, uniqueness: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :tenant_matches_project_and_quote

  def checkout!
    update!(status: "checkout_completed", checkout_completed_at: Time.current)
  end

  private

  def assign_order_id
    self.order_id ||= "ORDER-#{SecureRandom.hex(5).upcase}"
  end

  def copy_quote_fields
    return unless pricing_quote

    self.organization ||= pricing_quote.organization
    self.project ||= pricing_quote.project
    self.product_code ||= pricing_quote.product_code
    self.quantity ||= pricing_quote.quantity
  end

  def tenant_matches_project_and_quote
    if project.present? && organization.present? && project.organization_id != organization_id
      errors.add(:project, "must belong to the order organization")
    end

    if pricing_quote.present? && organization.present? && pricing_quote.organization_id != organization_id
      errors.add(:pricing_quote, "must belong to the order organization")
    end
  end
end
