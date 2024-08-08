module Submissions
  class EventAdditionService
    class << self
      # Note that this service does NOT persist changes to the submission object
      def call(submission, params)
        submission.events ||= []
        params[:events]&.each do |event|
          next if submission.events.any? { _1["id"] == event["id"] }

          event["submission_version"] ||= submission.current_version
          event["created_at"] ||= Time.zone.now
          event["updated_at"] ||= event["created_at"]

          submission.events << event.as_json
        end

        latest_event = submission.events.max_by { |ev| ev["created_at"] }
        submission.last_updated_at = latest_event["created_at"] if latest_event
      end
    end
  end
end
