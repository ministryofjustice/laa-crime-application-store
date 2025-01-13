module Nsm
  class ScheduleDeleteReviewedDocs < ApplicationJob
    sidekiq_options retry: 1

    def perform
      return false if filtered_claims.empty?

      filtered_claims.each do |claim|
        # DeleteReviewedClaimDocs.perform_later(claim)
      end
    rescue StandardError => e
      Rails.logger "GDPR delete reviewed NSM claims batch failed to run: #{e.message}"
    end

    def filtered_claims
      state = %w[granted part_grant rejected expired]

      Submission.where(application_type: "crm7",
                       state:)
                .where("last_updated_at: < ?", 6.months.ago)
    end
  end
end
