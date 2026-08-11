if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  required = %w[
    DATABASE_URL
    RAILS_MASTER_KEY
    SECRET_KEY_BASE
    RAILS_ALLOWED_HOSTS
  ]

  missing = required.select { |name| ENV[name].blank? }
  raise "Missing required production env vars: #{missing.join(', ')}" if missing.any?
end
