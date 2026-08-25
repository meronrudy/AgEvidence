class Activity < ApplicationRecord
  belongs_to :project, optional: true

  validates :activity_code, :occurred_at, :actor, :actor_kind, :title, :tone, presence: true
end
