module Submissions
  class UpdateService
    class << self
      def call(submission, params)
        submission.with_lock do
          submission.current_version += 1
          EventAdditionService.call(submission, params)

          new_state = params[:application_state]

          # Clear assignment on send_back (without adding to unassigned_user_ids)
          submission.assigned_user_id = nil if new_state == "sent_back"

          # Reset unassigned_user_ids when provider updates so caseworkers can be auto-assigned again
          submission.unassigned_user_ids = [] if new_state == "provider_updated"

          submission.assign_attributes(params.permit(:application_risk).merge(state: new_state))
          LaaCrimeFormsCommon::Hooks.submission_updated(submission, Time.zone.now)
          submission.save!
          submission.ordered_submission_versions.where(pending: true).destroy_all
          add_new_version(submission, params)
        end

        if ENV.fetch("SEND_EMAILS", "false") == "true" && submission.state == "provider_updated"
          Nsm::SubmissionMailer.notify(submission).deliver_now! if submission.application_type == "crm7"
          PriorAuthority::SubmissionMailer.notify(submission).deliver_now! if submission.application_type == "crm4"
        end
      end

      def add_new_version(submission, params)
        laa_reference = submission.ordered_submission_versions.last.application["laa_reference"]
        raise NoLaaReferenceError if laa_reference.nil?

        application_data = params[:application] ? params[:application].merge({ "laa_reference" => laa_reference }) : nil
        submission.ordered_submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          application: application_data,
          version: submission.current_version,
        )
      end
    end
  end
end
