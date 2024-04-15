Sidekiq.default_job_options = { retry: 5 }

# If this is enabled, sidekiq jobs will be run immediately
if ENV.fetch("RUN_SIDEKIQ_IN_TEST_MODE", false) == "true"
  require "sidekiq/testing"
  Sidekiq::Testing.inline!
end

if ENV["REDIS_HOST"].present? && ENV["REDIS_PASSWORD"].present?
  protocol = ENV.fetch("REDIS_PROTOCOL", "rediss")
  redis_url = "#{protocol}://:#{ENV.fetch('REDIS_PASSWORD',
                                          nil)}@#{ENV.fetch('REDIS_HOST',
                                                            nil)}:6379"
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url } if redis_url
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url } if redis_url
end
