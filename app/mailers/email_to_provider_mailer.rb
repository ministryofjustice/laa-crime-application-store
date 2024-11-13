class EmailToProviderMailer < GovukNotifyRails::Mailer
  # :nocov:
  def notify(message_class, submission)
    submission.with_lock do
      message = message_class.new(submission.latest_version.data)
      set_template(message.template)
      set_personalisation(**message.contents)
      mail(to: message.recipient)
    end
  end
  # :nocov:
end
