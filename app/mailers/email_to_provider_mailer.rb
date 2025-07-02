class EmailToProviderMailer < GovukNotifyRails::Mailer
  # :nocov:
  def notify(message_class, submission)
    submission.with_lock do
      message = message_class.new(submission.latest_version.application)
      set_template(message.template)
      set_personalisation(**message.contents)
      mail(to: submission.subscribers)
    end
  end
  # :nocov:
end
