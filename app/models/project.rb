class Project < ApplicationRecord
  include JsonBacked

  belongs_to :organization
  has_many :activities, dependent: :destroy
  has_many :source_records, dependent: :destroy
  has_many :evidence_records, dependent: :destroy
  has_many :model_runs, dependent: :destroy
  has_many :verifier_results, dependent: :destroy
  has_many :reliance_events, dependent: :destroy
  has_many :gaps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :artifacts, dependent: :destroy
  has_one :artifact, -> { where.not(status: "superseded").order(issued_at: :desc, created_at: :desc) }, class_name: "Artifact", inverse_of: :project
  has_many :evidence_cases, dependent: :destroy
  has_many :evaluations, dependent: :destroy
  has_many :determinations, dependent: :destroy

  json_field :metadata, default: {}

  validates :slug, :project_code, :name, :jurisdiction, :program, :scope, presence: true
end
