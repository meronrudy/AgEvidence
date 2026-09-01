class DomainMapping < ApplicationRecord
  STATUSES = %w[pending verified disabled].freeze

  belongs_to :organization

  before_validation :normalize_hostname

  validates :hostname, :status, presence: true
  validates :hostname, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :verified, -> { where(status: "verified").where.not(verified_at: nil) }
  scope :primary, -> { where(primary: true) }

  private

  def normalize_hostname
    self.hostname = hostname.to_s.downcase.strip
  end
end
