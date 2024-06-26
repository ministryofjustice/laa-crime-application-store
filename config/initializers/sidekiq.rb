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

Rails.logger.info("[Sidekiq] Application config initialising...")

Sidekiq.configure_client do |config|
  Rails.logger.info("[SidekiqClient] configuring sidekiq client...")
  config.redis = { url: redis_url } if redis_url
end

Sidekiq.configure_server do |config|
  Rails.logger.info("[SidekiqServer] configuring sidekiq server...")
  config.redis = { url: redis_url } if redis_url

  return unless ENV.fetch("ENABLE_PROMETHEUS_EXPORTER", "false") == "true"

  require 'prometheus_exporter/client'
  require 'prometheus_exporter/instrumentation'

  # Taken from https://github.com/discourse/prometheus_exporter?tab=readme-ov-file#sidekiq-metrics
  #
  config.server_middleware do |chain|
    Rails.logger.info "[SidekiqPrometheusExporter] Chaining middleware..."
    chain.add PrometheusExporter::Instrumentation::Sidekiq
  end
  config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler
  config.on :startup do
    Rails.logger.info "[SidekiqPrometheusExporter] Startup instrumention details..."

    PrometheusExporter::Instrumentation::Process.start type: 'sidekiq'
    PrometheusExporter::Instrumentation::SidekiqProcess.start
    PrometheusExporter::Instrumentation::SidekiqQueue.start(all_queues: true)
    PrometheusExporter::Instrumentation::SidekiqStats.start
  end

  at_exit do
    PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
  end
end
