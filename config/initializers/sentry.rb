EXCLUDE_PATHS = %w[/ping /ping.json /health /health.json].freeze

if ENV.fetch("SENTRY_DSN", nil).present?
  Sentry.init do |config|
    config.environment = ENV.fetch("ENV", "local")
    config.dsn = ENV.fetch("SENTRY_DSN", nil)
    config.breadcrumbs_logger = [:active_support_logger]
    config.release = ENV.fetch("BUILD_TAG", "unknown")

    config.excluded_exceptions += %w[RetryJobError]

    config.traces_sampler = lambda do |sampling_context|
      transaction_context = sampling_context[:transaction_context]
      transaction_name = transaction_context[:name]

      # Set traces_sample_rate to 1.0 to capture 100%
      # of transactions for performance monitoring.
      # We recommend adjusting this value in production.
      transaction_name.in?(EXCLUDE_PATHS) ? 0.0 : 0.05
    end

    # Opt in to new Rails error reporting API
    # https://edgeguides.rubyonrails.org/error_reporting.html
    config.rails.register_error_subscriber = true
  end
end
