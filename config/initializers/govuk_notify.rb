ActionMailer::Base.add_delivery_method :govuk_notify, GovukNotifyRails::Delivery,
                                       api_key: ENV.fetch("GOVUK_NOTIFY_API_KEY", nil)

class MailDeliveryJobWrapper < ActionMailer::MailDeliveryJob
  def serialize
    super.tap do |args|
      args["arguments"][3] = Array(args["arguments"][3])
    end
  end
end

# Set this so we ensure that the `to` list we pass to
# govuk_notify_rails is always an array
Rails.application.config.action_mailer.delivery_job = "MailDeliveryJobWrapper"
