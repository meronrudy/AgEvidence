class FeatureFlag < ApplicationRecord
  include JsonBacked

  belongs_to :organization

  json_field :metadata, default: {}

  validates :flag_key, presence: true, uniqueness: { scope: :organization_id }
end
