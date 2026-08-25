require "digest"

class StatementShare < ApplicationRecord
  ACCESS_LEVELS = %w[statement_only statement_and_summary full_bundle].freeze

  belongs_to :artifact
  belongs_to :created_by_user, class_name: "User", optional: true

  attr_reader :token

  before_validation :assign_token_digest, on: :create

  validates :token_digest, :access_level, :expires_at, presence: true
  validates :access_level, inclusion: { in: ACCESS_LEVELS }

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.digest_token(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.find_active_by_token(token)
    active.find_by(token_digest: digest_token(token))
  end

  def active?
    revoked_at.blank? && expires_at.future?
  end

  def record_access!
    increment!(:access_count)
    touch(:last_accessed_at)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def assign_token_digest
    @token ||= SecureRandom.urlsafe_base64(32)
    self.token_digest ||= self.class.digest_token(@token)
  end
end
