require "digest"

class ApiKey < ApplicationRecord
  include JsonBacked

  belongs_to :organization, optional: true

  json_field :scopes, default: []

  validates :key_code, :name, :token_hint, :token_digest, :status, presence: true
  validates :token_digest, uniqueness: true, allow_nil: true

  def self.digest_token(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.authenticate(token)
    active.find_by(token_digest: digest_token(token))
  end

  scope :active, -> { where(status: "Active", revoked_at: nil) }

  def revoked?
    revoked_at.present?
  end

  def allows?(scope)
    scopes.include?(scope.to_s) || scopes.include?("*")
  end

  def rotate!(token:)
    update!(
      token_digest: self.class.digest_token(token),
      token_hint: token_hint_for(token),
      last_used_at: nil,
      revoked_at: nil,
      status: "Active"
    )
  end

  def revoke!
    update!(status: "Revoked", revoked_at: Time.current)
  end

  private

  def token_hint_for(token)
    "#{token.first(10)}...#{token.last(4)}"
  end
end
