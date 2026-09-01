class EvidenceRecord < ApplicationRecord
  include JsonBacked

  belongs_to :project
  belongs_to :source_record, optional: true
  has_many :evidence_candidates, dependent: :nullify

  json_field :summary, :integrity, :processing, default: []
  json_field :payload, default: {}

  validates :record_code, :label, :record_type, :status, :schema_name, :source, :received_at, :projection, :digest, presence: true
  validate :source_record_belongs_to_project

  def organization
    project.organization
  end

  private

  def source_record_belongs_to_project
    return if source_record.blank? || project.blank? || source_record.project_id == project_id

    errors.add(:source_record, "must belong to the same project")
  end
end
