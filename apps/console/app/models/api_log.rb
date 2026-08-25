class ApiLog < ApplicationRecord
  include JsonBacked

  belongs_to :organization, optional: true

  json_field :trace, default: []
  json_field :request, :response, default: {}

  validates :log_code, :method, :endpoint, :status, :duration_ms, :occurred_at, :operation_id, presence: true
end
