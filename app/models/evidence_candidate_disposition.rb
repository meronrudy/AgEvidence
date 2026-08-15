class EvidenceCandidateDisposition < ApplicationRecord
  include JsonBacked

  belongs_to :evidence_candidate
  belongs_to :actor, class_name: "User", optional: true

  json_field :metadata, default: {}

  validates :status, :reason, :recorded_at, presence: true
  validates :status, inclusion: { in: EvidenceCandidate::STATUSES }

  def organization
    evidence_candidate.organization
  end

  def project
    evidence_candidate.project
  end
end
