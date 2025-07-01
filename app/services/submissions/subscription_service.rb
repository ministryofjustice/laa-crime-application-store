module Submissions
  class SubscriptionService
    class << self
      def subscribe(submission, email)
        return if submission.subscribers.include?(email)

        submission.with_lock do
          submission.subscribers << email
          submission.save!
        end
      end

      def unsubscribe(submission, email)
        return unless submission.subscribers.include?(email)

        submission.with_lock do
          submission.subscribers.delete(email)
          submission.save!
        end
      end
    end
  end
end
