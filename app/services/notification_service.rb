class NotificationService
  class << self
    def call(submission, role)
      Subscriber.where.not(subscriber_type: role).find_each do |subscriber|
        NotifySubscriber.new.perform(subscriber.id, submission)
      end
    end
  end
end
