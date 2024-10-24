module Submissions
  class UpdateService
    class << self
      def call(submission, params, role)
        submission.with_lock do
          submission.current_version += 1
          EventAdditionService.call(submission, params)
          submission.update!(params.permit(:application_risk).merge(state: params[:application_state]))
          add_new_version(submission, params)
        end
        NotificationService.call(submission, role)
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
