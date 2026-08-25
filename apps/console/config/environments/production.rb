Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  config.require_master_key = ENV["SECRET_KEY_BASE_DUMMY"].blank?
  config.force_ssl = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=31536000"
  }

  config.assets.compile = false

  config.active_storage.service = :local
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  config.active_job.queue_name_prefix = "agevidence_production"

  config.action_controller.perform_caching = true
  config.cache_store = :memory_store, { size: 64.megabytes }

  config.log_level = :info
  config.log_tags = [:request_id]

  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  allowed_hosts = ENV.fetch("RAILS_ALLOWED_HOSTS", "console.agevidence.com").split(",").map(&:strip)
  config.hosts = allowed_hosts

  config.session_store :cookie_store,
    key: "_agevidence_session",
    secure: true,
    httponly: true,
    same_site: :strict

  config.action_mailer.delivery_method = :smtp if ENV["SMTP_HOST"].present?
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_HOST"],
    port: ENV.fetch("SMTP_PORT", 587),
    authentication: :login,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    enable_starttls_auto: true
  }.compact
  config.action_mailer.default_url_options = { host: allowed_hosts.first, protocol: "https" }

  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
end
