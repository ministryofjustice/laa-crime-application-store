class NotificationService
  class << self
    def call(submission, role)
      Subscriber.where.not(subscriber_type: role).find_each do |subscriber|
        NotifySubscriber.perform_later(subscriber.id, submission)
      end
    end
  end
end
