class EvidenceSchema < ApplicationRecord
  self.table_name = "schemas"

  validates :schema_code, :name, :version, :events_count, :status, presence: true
end
