class ReviewDecision < ApplicationRecord
  belongs_to :review
  belongs_to :user, optional: true

  validates :decision_code, :decision, :reviewer, :recorded_at, :rationale, presence: true
end
