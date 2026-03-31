module Submissions
  class EventAdditionService
    class << self
      # Note that this service does NOT persist changes to the submission object
      def call(submission, params)
        submission.caseworker_history_events ||= []
        params[:events]&.each do |event|
          next if submission.caseworker_history_events.any? { _1["id"] == event["id"] }

          event["submission_version"] ||= submission.current_version
          event["created_at"] ||= Time.zone.now
          event["updated_at"] ||= event["created_at"]

          submission.caseworker_history_events << event.as_json
        end

        latest_event = submission.caseworker_history_events.reject { _1["does_not_constitute_update"] }.max_by { _1["created_at"] }
        submission.last_updated_at = latest_event["created_at"] if latest_event
      end
    end
  end
end
