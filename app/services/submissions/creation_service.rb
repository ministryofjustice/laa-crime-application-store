module Submissions
  class CreationService
    AlreadyExistsError = Class.new(StandardError)
    class << self
      def call(params)
        raise AlreadyExistsError if Submission.find_by(id: params[:application_id])

        submission = Submission.create!(initial_data(params))
        submission.with_lock do
          add_version(submission, params)
          LaaCrimeFormsCommon::Hooks.submission_created(submission, ActiveRecord::Base.connection, Time.zone.now) do |new_state, message_class|
            on_state_change(submission, new_state, message_class)
          end
          last_updated_at = params.dig(:application, :updated_at)&.to_time || submission.created_at
          submission.update!(last_updated_at:)
        end

        submission
      end

      def initial_data(params)
        params.permit(:application_type, :application_risk)
              .merge(current_version: 1,
                     state: params[:application_state],
                     id: params[:application_id])
      end

      def add_version(submission, params)
        submission.ordered_submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          application: params[:application],
          version: 1,
        )
      end

      def on_state_change(submission, new_state, message_class)
        submission.update!(
          state: new_state,
          current_version: submission.current_version + 1,
        )

        latest_version = submission.latest_version
        submission.ordered_submission_versions.create!(
          json_schema_version: latest_version.json_schema_version,
          application: latest_version.application.merge("updated_at" => Time.zone.now, "status" => new_state),
          version: submission.current_version,
        )

        EmailToProviderMailer.notify(message_class, submission).deliver_later!
      end
    end
  end
end
