module Nsm
  class DeleteReviewedClaimDocs < ApplicationJob
    after_perform do |job|
      Rails.logger "GDPR delete supporting docs for reviewed NSM claim : #{job.args.first}"
    end

    def perform(submission)
      purge_docs(submission)
    end

    def purge_docs(submission)
      submission.supporting_evidence.map do |file|
        file_uploader.destroy(file.file_path)
      end

      now = Time.zone.now
      submission.with_lock do
        submission.current_version += 1
        submission.last_updated_at = now
        submission.caseworker_history_events << build_delete_supporting_evidence_event(now, submission.current_version)
        submission.save!

        latest_version = submission.latest_version
        submission.ordered_submission_versions.create!(
          json_schema_version: latest_version.json_schema_version,
          application: latest_version.application.merge("updated_at" => now, "uploads_purged" => true),
          version: submission.current_version,
        )
      end
    end

    def build_delete_supporting_evidence_event(now, current_version)
      {
        submission_version: current_version,
        id: SecureRandom.uuid,
        created_at: now,
        details: {comment: "GDPR delete supporting evidence"},
        updated_at: now,
        event_type: "gdpr_delete_supporting_evidence",
        public: true,
        does_not_constitute_update: true,
      }
    end

  private

    def file_uploader
      @file_uploader ||= FileUpload::FileUploader.new
    end

    def submission
      @submission ||= Submission.find(job.arguments.first)
    end
  end
end
