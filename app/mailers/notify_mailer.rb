# frozen_string_literal: true

class NotifyMailer < GovukNotifyRails::Mailer
  rescue_from 'Notifications::Client::BadRequestError' do |e|
    if HostEnv.production? || e.message.exclude?('team-only API')
      Rails.logger.warn("Reraising exception #{e.class} with message \"#{e.message}\"")
      raise e
    else
      Rails.logger.warn("Swallowing exception #{e.class} with message \"#{e.message}\"")
    end
  end
end
