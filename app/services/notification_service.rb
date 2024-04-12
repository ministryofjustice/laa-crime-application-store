class NotificationService
  class << self
    def call(submission_id)
      # TODO: Once roles are in place, only notify subscribers with a different role to the
      # role of the client who made this change
      Subscriber.find_each do |subscriber|
        # TODO: When sidekiq is set up, make this perform_later
        NotifySubscriber.new.perform(subscriber.webhook_url, submission_id)
      end
    end
  end
end
