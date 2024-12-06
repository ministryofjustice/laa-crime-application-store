module Submissions
  class UpdateService
    class << self
      def call(submission, params)
        submission.with_lock do
          submission.current_version += 1
          EventAdditionService.call(submission, params)
          submission.assign_attributes(params.permit(:application_risk).merge(state: params[:application_state]))
          LaaCrimeFormsCommon::Hooks.submission_updated(submission, Time.zone.now)
          submission.save!
          submission.ordered_submission_versions.where(pending: true).destroy_all
          add_new_version(submission, params)
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
