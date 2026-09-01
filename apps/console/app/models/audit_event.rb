# app/models/audit_event.rb
class AuditEvent < ApplicationRecord
  include JsonBacked

  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :organization, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  json_field :metadata, default: {}

  validates :action, presence: true
  validates :auditable_type, presence: true, if: -> { auditable_id.present? }
  validates :auditable_id, presence: true, if: -> { auditable_type.present? }

  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_actor, ->(user) { where(actor: user) }
  scope :for_auditable, ->(record) { where(auditable: record) }
  scope :recent, -> { order(created_at: :desc) }

  def self.log!(action:, actor: nil, organization: nil, auditable: nil, metadata: {})
    create!(
      action: action,
      actor: actor,
      organization: organization,
      auditable: auditable,
      metadata: metadata,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent],
      request_id: metadata[:request_id]
    )
  end
end
