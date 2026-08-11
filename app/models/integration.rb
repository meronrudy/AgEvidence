class Integration < ApplicationRecord
  include JsonBacked

  belongs_to :organization, optional: true

  json_field :events, default: []

  validates :integration_code, :name, :provider, :status, presence: true
end
