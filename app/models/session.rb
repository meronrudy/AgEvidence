# app/models/session.rb
class Session < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :role, class_name: 'Role'

  validates :user_id, presence: true
  validates :organization_id, presence: true
  validates :role_id, presence: true
  validates :ip_address, presence: true
  validates :user_agent, presence: true

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }

  # instance methods
  def activate!
    update!(status: 'active')
  end

  def deactivate!
    update!(status: 'inactive')
  end
end
