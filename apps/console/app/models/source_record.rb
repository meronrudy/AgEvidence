require "uri"

class SourceRecord < ApplicationRecord
  include JsonBacked

  URI_SCHEMES = %w[https s3 evidence].freeze
  DISCLOSURE_STATUSES = %w[available restricted].freeze
  STATUSES = %w[received validated rejected needs_review].freeze

  belongs_to :organization
  belongs_to :project
  has_many :evidence_records, dependent: :nullify
  has_many :gaps, dependent: :nullify

  json_field :metadata, default: {}

  before_validation :assign_record_code
  before_validation :assign_organization_from_project

  validates :record_code, :source_system, :document_id, :evidence_type, :evidence_class,
            :controlled_uri, :commitment, :disclosure_status, :status, presence: true
  validates :record_code, uniqueness: true, format: { with: /\ASR-[A-Z0-9-]+\z/ }
  validates :document_id, uniqueness: { scope: :project_id }
  validates :disclosure_status, inclusion: { in: DISCLOSURE_STATUSES }
  validates :status, inclusion: { in: STATUSES }
  validate :project_belongs_to_organization
  validate :controlled_uri_has_allowed_scheme
  validate :commitment_has_algorithm_and_value

  scope :chronological, -> { order(created_at: :asc, record_code: :asc) }

  def organization
    super || project&.organization
  end

  def public_bundle_payload
    {
      "contract_version" => "source-record.v0",
      "record_code" => record_code,
      "source_system" => source_system,
      "document_id" => document_id,
      "evidence_type" => evidence_type,
      "evidence_class" => evidence_class,
      "controlled_uri" => controlled_uri,
      "commitment" => commitment,
      "disclosure_status" => disclosure_status,
      "status" => status
    }
  end

  private

  def assign_record_code
    self.record_code = "SR-#{SecureRandom.hex(5).upcase}" if record_code.blank?
  end

  def assign_organization_from_project
    self.organization ||= project&.organization
  end

  def project_belongs_to_organization
    return if project.blank? || organization.blank? || project.organization_id == organization_id

    errors.add(:project, "must belong to the same organization")
  end

  def controlled_uri_has_allowed_scheme
    scheme = URI.parse(controlled_uri.to_s).scheme
    errors.add(:controlled_uri, "must use https://, s3://, or evidence://") unless URI_SCHEMES.include?(scheme)
  rescue URI::InvalidURIError
    errors.add(:controlled_uri, "is invalid")
  end

  def commitment_has_algorithm_and_value
    return if commitment.to_s.match?(/\A[a-z0-9][a-z0-9_-]*:[A-Za-z0-9+\/=_-]{12,}\z/)

    errors.add(:commitment, "must include an algorithm and commitment value")
  end
end
