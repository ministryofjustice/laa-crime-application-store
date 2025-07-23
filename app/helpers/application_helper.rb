module ApplicationHelper
  def handle_error(exception)
    Rails.logger.error exception
    Sentry.capture_exception(exception) if ENV.fetch("SENTRY_DSN", nil).present?
  end
end
