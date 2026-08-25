class ProgramProfile < ApplicationRecord
  include JsonBacked

  has_many :requirements, dependent: :destroy
  has_many :evaluations, dependent: :destroy
  has_many :determinations, dependent: :destroy
  has_many :artifact_profiles, dependent: :destroy

  json_field :composition, :version_diff, default: []
  json_field :version_impact, :comparison, default: {}
  json_field :outcome_vocabulary, :limitation_templates, default: []
  json_field :issuance_policy, default: {}

  validates :slug, :code, :name, :status, :profile_version, :program, :scope, presence: true
end
