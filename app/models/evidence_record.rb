class EvidenceRecord < ApplicationRecord
  include JsonBacked

  belongs_to :project

  json_field :summary, :integrity, :processing, default: []
  json_field :payload, default: {}

  validates :record_code, :label, :record_type, :status, :schema_name, :source, :received_at, :projection, :digest, presence: true
end
