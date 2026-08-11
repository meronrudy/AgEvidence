class Organization < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :invitations, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :audit_events, dependent: :nullify
  has_many :api_keys, dependent: :destroy
  has_many :api_logs, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :evidence_cases, dependent: :destroy

  validates :name, :environment, presence: true

  def role(name)
    roles.find_by!(name: name.to_s)
  end
end
