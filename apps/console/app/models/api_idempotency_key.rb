class ApiIdempotencyKey < ApplicationRecord
  include JsonBacked

  belongs_to :organization

  json_field :response, default: {}

  validates :key, :method, :path, :status, presence: true
end
