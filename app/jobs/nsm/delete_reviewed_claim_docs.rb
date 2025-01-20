module Nsm
  class DeleteReviewedClaimDocs < ApplicationJob
    class GDPRDeletionError < StandardError; end

    def perform(submission_id)
      submission = Submission.find(submission_id)
      now = Time.zone.now
      supporting_evidences = submission.latest_version.application["supporting_evidences"]

      supporting_evidences.each do |document|
        if file_uploader.destroy(document["file_path"])
          Rails.logger.info "Deleted #{document['id']} for submission #{submission.id}"
        else
          Rails.logger.error "Delete failed for document: #{document['id']} submission: #{submission.id}"
          raise GDPRDeletionError, "Failed delete document: #{document['id']} submission: #{submission.id}"
        end
      end

      submission.with_lock do
        submission.current_version += 1
        submission.last_updated_at = now
        submission.caseworker_history_events << build_delete_supporting_evidence_event(now, submission.current_version)
        submission.save!

        latest_version = submission.latest_version
        submission.ordered_submission_versions.create!(
          json_schema_version: latest_version.json_schema_version,
          application: latest_version.application.merge("updated_at" => now,
                                                        "uploads_purged" => true),
          version: submission.current_version,
        )
      end
    end

  private

    def build_delete_supporting_evidence_event(now, current_version)
      {
        submission_version: current_version,
        id: SecureRandom.uuid,
        created_at: now,
        details: { comment: "Automated GDPR deletion of supporting evidence" },
        updated_at: now,
        event_type: "gdpr_supporting_evidence",
        public: true,
        does_not_constitute_update: true,
      }
    end

    def file_uploader
      @file_uploader ||= FileUpload::FileUploader.new
    end
  end
end
