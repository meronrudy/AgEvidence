class Determination < ApplicationRecord
  include JsonBacked

  belongs_to :program_profile
  belongs_to :project
  belongs_to :evaluation, optional: true
  belongs_to :supersedes_determination, class_name: "Determination", optional: true
  has_many :superseding_determinations, class_name: "Determination", foreign_key: :supersedes_determination_id, dependent: :nullify, inverse_of: :supersedes_determination

  json_field :result, default: {}

  validates :determination_code, :project_name, :outcome, :adapter, :digest, :published_at, :status, presence: true
  validates :status, inclusion: { in: %w[published superseded withdrawn] }

  def organization
    project.organization
  end

  def supersede!(metadata: {})
    update!(status: "superseded", superseded_at: Time.current)
    AuditEvent.log!(
      action: "determination_superseded",
      organization: organization,
      auditable: self,
      metadata: metadata
    )
  end
end
