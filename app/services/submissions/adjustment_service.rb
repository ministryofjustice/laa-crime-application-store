module Submissions
  class AdjustmentService
    class << self
      def call(submission, params)
        submission.with_lock do
          pending_version = submission.ordered_submission_versions.find_or_initialize_by(pending: true) do |new_pending_version|
            new_pending_version.version = submission.current_version + 1
            new_pending_version.json_schema_version = submission.latest_version.json_schema_version
          end

          pending_version.update!(application: params[:application])
        end
      end
    end
  end
end
