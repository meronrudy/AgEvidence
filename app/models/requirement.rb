class Requirement < ApplicationRecord
  include JsonBacked

  belongs_to :program_profile

  json_field :accepted_evidence, default: []

  validates :requirement_code, :title, :category, :evaluation_mode, :status, presence: true
end
