module Submissions
  class UpdateService
    class << self
      def call(params, role)
        submission = Submission.find(params[:id])
        submission.with_lock do
          add_events(submission, params)
          submission.current_version += 1 if params[:application]
          if params.permit(:application_state, :application_risk).keys.any?
            submission.update!(params.permit(:application_state, :application_risk))
          else
            submission.save!
          end
          add_new_version(submission, params) if params[:application]
        end
        NotificationService.call(params[:id], role)
      end

      def add_events(submission, params)
        params[:events]&.each do |event|
          submission.events << event unless submission.events.find { _1["id"] == event["id"] }
        end
      end

      def add_new_version(submission, params)
        submission.submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          application: params[:application],
          version: submission.current_version,
        )
      end
    end
  end
end
