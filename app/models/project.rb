class Project < ApplicationRecord
  include JsonBacked

  belongs_to :organization
  has_many :activities, dependent: :destroy
  has_many :evidence_records, dependent: :destroy
  has_many :gaps, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one :artifact, dependent: :destroy
  has_many :evidence_cases, dependent: :destroy

  json_field :metadata, default: {}

  validates :slug, :project_code, :name, :jurisdiction, :program, :scope, presence: true
end
