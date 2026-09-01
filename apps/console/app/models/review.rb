class Review < ApplicationRecord
  belongs_to :project
  has_many :review_decisions, dependent: :destroy

  validates :review_code, :requirement_code, :title, :state, presence: true

  scope :open, -> { where(state: "open") }

  def organization
    project.organization
  end
end
