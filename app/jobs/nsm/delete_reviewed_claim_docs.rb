module Nsm
  class DeleteReviewedClaimDocs < ApplicationJob
    after_perform do |job|
      claim = job.arguments.first
      event = Common::HistoryEvent.new(
        event_type: "gdpr_delete_supporting_documents",
        event_date: Time.zone.now,
        event_data: { version: claim.current_version },
      )
      claim.events << event
    end

    def perform(claim)
      # ie LaaCrimeFormsCommon::NSM::GdprDocumentDeleterService.call(claim)
    rescue StandardError => e
      Rails.logger "GDPR delete supporting docs for NSM reviewed claim: #{claim.id} failed to run: #{e.message}"
    end
  end
end
