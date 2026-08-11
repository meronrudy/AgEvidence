class Evaluation < ApplicationRecord
  belongs_to :program_profile

  validates :evaluation_code, :project_name, :outcome, :satisfied, :evaluated_at, presence: true
end
