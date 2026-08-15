class Evaluation < ApplicationRecord
  include JsonBacked

  belongs_to :program_profile
  belongs_to :project
  has_many :determinations, dependent: :restrict_with_exception

  json_field :result, default: {}

  validates :evaluation_code, :project_name, :outcome, :satisfied, :evaluated_at,
            :input_digest, :profile_version, :status, presence: true
  validates :status, inclusion: { in: %w[current stale superseded] }

  def organization
    project.organization
  end

  def stale?
    stale_at.present? || status == "stale"
  end

  def mark_stale!(metadata: {})
    update!(status: "stale", stale_at: Time.current)
    AuditEvent.log!(
      action: "evaluation_marked_stale",
      organization: organization,
      auditable: self,
      metadata: metadata
    )
  end
end
