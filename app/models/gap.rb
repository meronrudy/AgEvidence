class Gap < ApplicationRecord
  include JsonBacked

  belongs_to :project
  belongs_to :source_record, optional: true
  belongs_to :evidence_record, optional: true

  json_field :expected, :observed, :related_evidence, default: []

  validates :gap_code, :requirement_code, :severity, :title, :explanation, :action, :status, presence: true
  validates :severity, inclusion: { in: %w[low medium high critical] }
  validates :status, inclusion: { in: %w[open resolved superseded] }
  validate :basis_belongs_to_project

  scope :open, -> { where(status: "open") }
  scope :blocking, -> { where(blocking: true) }

  def organization
    project.organization
  end

  private

  def basis_belongs_to_project
    if source_record.present? && project.present? && source_record.project_id != project_id
      errors.add(:source_record, "must belong to the same project")
    end

    if evidence_record.present? && project.present? && evidence_record.project_id != project_id
      errors.add(:evidence_record, "must belong to the same project")
    end
  end
end
