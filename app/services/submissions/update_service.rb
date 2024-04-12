module Submissions
  class UpdateService
    class << self
      def call(params)
        submission = Submission.find(params[:id])
        submission.with_lock do
          add_events(submission, params)
          submission.current_version += 1 if params[:application]
          submission.update!(params.permit(:application_state, :application_risk))
          add_new_version(submission, params) if params[:application]
        end
        NotificationService.call(params[:id])
      end

      def add_events(submission, params)
        params[:events]&.each do |event|
          # TODO: Deduplication here
          submission.events << event
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
