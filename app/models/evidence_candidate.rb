class EvidenceCandidate < ApplicationRecord
  include JsonBacked

  STATUSES = %w[review_required accepted rejected needs_more_evidence superseded].freeze

  belongs_to :model_run
  belongs_to :evidence_record, optional: true
  belongs_to :reviewed_by_user, class_name: "User", optional: true
  has_many :evidence_candidate_dispositions, dependent: :destroy

  json_field :basis, :limitations, default: []

  before_validation :assign_candidate_code

  validates :candidate_code, :candidate_type, :claim, :status, presence: true
  validates :candidate_code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  def organization
    model_run.organization
  end

  def project
    model_run.project
  end

  private

  def assign_candidate_code
    self.candidate_code = "EC-#{SecureRandom.hex(5).upcase}" if candidate_code.blank?
  end
end
