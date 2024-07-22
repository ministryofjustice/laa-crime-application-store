Rails.application.configure do
  config.lograge.enabled = Rails.env.production?
  config.lograge.base_controller_class = 'ActionController::API'
  config.lograge.logger = ActiveSupport::Logger.new($stdout)
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Reduce noise in the logs by ignoring the healthcheck actions
  config.lograge.ignore_actions = %w[
    HealthController#show
  ]

  # Important: the `controller` might not be a full-featured
  # `ApplicationController` but instead a `BareApplicationController`
  config.lograge.custom_payload do |controller|
    {
      client_role: controller.current_client_role
    }
  end
end
