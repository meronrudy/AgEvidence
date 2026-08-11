class ApiKey < ApplicationRecord
  belongs_to :organization, optional: true

  validates :key_code, :name, :token_hint, :status, presence: true
end
