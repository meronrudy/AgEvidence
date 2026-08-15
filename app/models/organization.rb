class Organization < ApplicationRecord
  has_many :projects, dependent: :destroy
  has_many :activities, through: :projects
  has_many :artifacts, through: :projects, source: :artifacts
  has_many :determinations, through: :projects
  has_many :evaluations, through: :projects
  has_many :evidence_records, through: :projects
  has_many :gaps, through: :projects
  has_many :reviews, through: :projects
  has_many :roles, dependent: :destroy
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships
  has_many :invitations, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :audit_events, dependent: :nullify
  has_many :source_records, dependent: :destroy
  has_many :model_runs, dependent: :destroy
  has_many :verifier_results, dependent: :destroy
  has_many :reliance_events, dependent: :destroy
  has_many :api_keys, dependent: :destroy
  has_many :api_logs, dependent: :destroy
  has_many :integrations, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_many :evidence_cases, dependent: :destroy
  has_many :feature_flags, dependent: :destroy

  validates :name, :environment, presence: true

  def role(name)
    roles.find_by!(name: name.to_s)
  end
end
