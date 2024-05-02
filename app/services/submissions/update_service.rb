module Submissions
  class UpdateService
    class << self
      def call(submission, params, role)
        submission.with_lock do
          add_events(submission, params)
          submission.current_version += 1 if params[:application]
          submission.update!(params.permit(:application_state, :application_risk))
          add_new_version(submission, params) if params[:application]
        end
        NotificationService.call(params[:id], role)
      end

      def add_events(submission, params)
        submission.events ||= []
        params[:events]&.each do |event|
          next if submission.events.any? { _1["id"] == event["id"] }

          submission.events << event.as_json
        end
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