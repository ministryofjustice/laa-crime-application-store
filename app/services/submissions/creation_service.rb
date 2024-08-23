module Submissions
  class CreationService
    AlreadyExistsError = Class.new(StandardError)
    class << self
      def call(params, role)
        raise AlreadyExistsError if Submission.find_by(id: params[:application_id])

        Submission.transaction do
          submission = Submission.create!(initial_data(params))
          submission.ordered_submission_versions.create!(
            json_schema_version: params[:json_schema_version],
            application: params[:application],
            version: 1,
          )

          last_updated_at = params.dig(:application, :updated_at)&.to_time || submission.created_at
          submission.update_columns(last_updated_at:)
        end
        NotificationService.call(params[:application_id], role)
      end

      def initial_data(params)
        params.permit(:application_type, :application_risk)
              .merge(current_version: 1,
                     state: params[:application_state],
                     id: params[:application_id])
      end
    end
  end
end
