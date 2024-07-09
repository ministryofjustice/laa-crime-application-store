module Submissions
  class EventCreationService
    class << self
      def call(submission, params)
        submission.events ||= []
        params[:events]&.each do |event|
          next if submission.events.any? { _1["id"] == event["id"] }

          event["submission_version"] ||= submission.current_version
          event["created_at"] ||= Time.zone.now
          event["updated_at"] ||= event["created_at"]
          submission.events << event.as_json
        end
      end
    end
  end
end
