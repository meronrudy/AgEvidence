class Determination < ApplicationRecord
  belongs_to :program_profile

  validates :determination_code, :project_name, :outcome, :adapter, :digest, :published_at, presence: true
end
