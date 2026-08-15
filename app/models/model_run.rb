class ModelRun < ApplicationRecord
  include JsonBacked

  STATUSES = %w[queued running completed failed superseded].freeze

  belongs_to :organization
  belongs_to :project
  has_many :evidence_candidates, dependent: :destroy

  json_field :output, :metadata, default: {}

  before_validation :assign_run_code
  before_validation :assign_organization_from_project

  validates :run_code, :adapter_name, :adapter_version, :input_commitment, :status, :started_at, presence: true
  validates :run_code, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validate :project_belongs_to_organization

  def organization
    super || project&.organization
  end

  private

  def assign_run_code
    self.run_code = "RUN-#{SecureRandom.hex(5).upcase}" if run_code.blank?
  end

  def assign_organization_from_project
    self.organization ||= project&.organization
  end

  def project_belongs_to_organization
    return if project.blank? || organization.blank? || project.organization_id == organization_id

    errors.add(:project, "must belong to the same organization")
  end
end
