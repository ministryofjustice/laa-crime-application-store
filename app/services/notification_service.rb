class NotificationService
  class << self
    def call(submission_id, role)
      Subscriber.where.not(subscriber_type: role).find_each do |subscriber|
        NotifySubscriber.perform_later(subscriber.id, submission_id)
      end
    end
  end
end
