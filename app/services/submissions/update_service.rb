module Submissions
  class UpdateService
    class << self
      def call(submission, params, role)
        submission.with_lock do
          submission.current_version += 1
          add_events(submission, params)
          submission.update!(params.permit(:application_state, :application_risk))
          add_new_version(submission, params)
        end
        NotificationService.call(params[:id], role)
      end

      def add_events(submission, params, save: false)
        submission.events ||= []
        params[:events]&.each do |event|
          next if submission.events.any? { _1["id"] == event["id"] }

          event["submission_version"] ||= submission.current_version
          event["created_at"] ||= Time.zone.now
          event["updated_at"] ||= event["created_at"]

          submission.events << event.as_json
        end
        save && submission.save!
      end

      def add_new_version(submission, params)
        submission.ordered_submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          application: params[:application],
          version: submission.current_version,
        )
      end
    end
  end
end
