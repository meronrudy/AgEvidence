Rails.application.config.middleware.use Rack::Attack

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle("logins/ip", limit: 10, period: 1.minute) do |request|
  request.ip if request.path == "/users/sign_in" && request.post?
end

Rack::Attack.throttle("verification/ip", limit: 120, period: 1.minute) do |request|
  request.ip if request.path.start_with?("/verify")
end

Rack::Attack.throttle("api/key_or_ip", limit: 300, period: 1.minute) do |request|
  if request.path.start_with?("/api/v1")
    request.get_header("HTTP_AUTHORIZATION").presence || request.ip
  end
end
