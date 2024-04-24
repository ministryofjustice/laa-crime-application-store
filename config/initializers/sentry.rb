if ENV.fetch("SENTRY_DSN", nil).present?
  Sentry.init do |config|
    config.environment = ENV.fetch('ENV', 'local')
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [:active_support_logger]
    config.release = ENV.fetch("BUILD_TAG", "unknown")
    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for performance monitoring.
    # We recommend adjusting this value in production.
    config.traces_sample_rate = 0.05
    # or
    config.traces_sampler = lambda do |_context|
      true
    end

    # Opt in to new Rails error reporting API
    # https://edgeguides.rubyonrails.org/error_reporting.html
    config.rails.register_error_subscriber = true
  end
end
