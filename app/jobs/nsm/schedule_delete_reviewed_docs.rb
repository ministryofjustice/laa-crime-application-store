module Nsm
  class ScheduleDeleteReviewedDocs < ApplicationJob
    sidekiq_options retry: 5

    def perform
      return if filtered_claims.empty?

      filtered_claims.each do |claim|
        Nsm::DeleteReviewedClaimDocs.perform_later(claim)
      end
    end

    def filtered_claims
      state = %w[granted part_grant rejected expired]

      # TODO: need to filter claims out if claim has previously been GDPRd

      Submission.joins("LEFT JOIN application_version latest_version ON latest_version.application_id = application.id AND
        latest_version.version = (SELECT MAX(version)
        FROM application_version all_versions
        WHERE all_versions.application_id = application.id)")
        .where(state:, application_type: "crm7", last_updated_at: ..6.months.ago)
        .where("(latest_version.application->>'documents_purged') NOT null")

      # Submission.where(application_type: "crm7",
      #                  state:,
      #                  last_updated_at: ..6.months.ago)
    end
  end
end
