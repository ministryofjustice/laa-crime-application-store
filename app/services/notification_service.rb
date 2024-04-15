class NotificationService
  class << self
    def call(submission_id, role)
      Subscriber.where.not(subscriber_type: role).find_each do |subscriber|
        # TODO: When sidekiq is set up, make this perform_later
        NotifySubscriber.new.perform(subscriber.webhook_url, submission_id)
      end
    end
  end
end
