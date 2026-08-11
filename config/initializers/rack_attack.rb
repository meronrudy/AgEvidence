Rails.application.config.middleware.use Rack::Attack

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle("logins/ip", limit: 10, period: 1.minute) do |request|
  request.ip if request.path == "/users/sign_in" && request.post?
end

Rack::Attack.throttle("verification/ip", limit: 120, period: 1.minute) do |request|
  request.ip if request.path.start_with?("/verify")
end
