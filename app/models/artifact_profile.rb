class ArtifactProfile < ApplicationRecord
  include JsonBacked

  belongs_to :program_profile

  json_field :layout, :recipient_rules, :retention, default: {}

  validates :profile_code, :profile_version, :status, presence: true
end
