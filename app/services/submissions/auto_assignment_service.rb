module Submissions
  class AutoAssignmentService
    class << self
      def call(params)
        Submission.with_advisory_lock("assign user") do
          base_query = Submission.joins("LEFT JOIN application_version latest_version ON latest_version.application_id = application.id AND
                                        latest_version.version = (SELECT MAX(version)
                                                                  FROM application_version all_versions
                                                                  WHERE all_versions.application_id = application.id)")
                                 .where(application_type: params[:application_type],
                                        assigned_user_id: nil,
                                        state: %i[submitted provider_updated])
                                 .where.not("? = ANY(unassigned_user_ids)", params[:current_user_id])

          LaaCrimeFormsCommon::Assignment.build_assignment_query(
            base_query,
            params[:application_type],
            fields_to_select: "application.*",
            updated_at_column: :last_updated_at,
            data_column: "latest_version.application",
            risk_column: "application.application_risk",
            sanitizer: Arel,
          ).first.tap { _1&.update!(assigned_user_id: params[:current_user_id]) }
        end
      end
    end
  end
end
