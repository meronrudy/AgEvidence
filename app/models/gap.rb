class Gap < ApplicationRecord
  include JsonBacked

  belongs_to :project

  json_field :expected, :observed, :related_evidence, default: []

  validates :gap_code, :requirement_code, :severity, :title, :explanation, :action, presence: true
end
