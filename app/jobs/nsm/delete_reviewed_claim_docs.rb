module Nsm
  class DeleteReviewedClaimDocs < ApplicationJob
    class GDPRDeletionError < StandardError; end

    def perform(submission_id)
      now = Time.zone.now
      submission = Submission.find(submission_id)
      latest_version_data = submission.latest_version.application
      docs_to_destroy = []
      supporting_evidences = latest_version_data["supporting_evidences"]
      further_informations = latest_version_data["further_information"]

      docs_to_destroy << supporting_evidences.pluck("file_path")

      if further_informations
        further_informations.each do |fi|
          docs = fi["documents"]
          next unless docs.any?

          docs.each do |doc|
            docs_to_destroy << doc["file_path"]
          end
        end
      end

      return unless docs_to_destroy.flatten.any?

      docs_to_destroy.flatten.each do |file_path|
        if destroy_file(file_path)
          Rails.logger.info "Deleted #{file_path} for submission #{submission.id}"

          SubmissionVersion.where(application_id: submission_id).find_each do |submission_version|
            submission_version.with_lock do
              submission_version.application = redact_file_names(submission_version.application, file_path)
              submission_version.save!
            end
          end
        else
          Rails.logger.error "Delete failed for document: #{file_path} submission: #{submission.id}"
        end
      end

      submission.with_lock do
        submission.current_version += 1
        submission.caseworker_history_events << build_delete_supporting_evidence_event(now, submission.current_version)
        submission.save!(touch: false)

        latest_version = submission.latest_version
        submission.ordered_submission_versions.create!(
          json_schema_version: latest_version.json_schema_version,
          application: latest_version.application.merge("gdpr_documents_deleted" => true),
          version: submission.current_version,
        )
      end
    end

    def redact_file_names(application, path)
      paths = %w[file_path file_name]

      case application
      when Hash
        application.each do |key, value|
          application[key] = if paths.include?(key.to_s) && value == path
                               "<Redacted for GDPR compliance>"
                             else
                               redact_file_names(value, path)
                             end
        end
      when Array
        application.map! { |item| redact_file_names(item, path) }
      else
        application
      end
      application
    end

  private

    def destroy_file(file_path)
      file_uploader.destroy(file_path) if file_uploader.exists?(file_path)
    end

    def build_delete_supporting_evidence_event(now, current_version)
      {
        submission_version: current_version,
        id: SecureRandom.uuid,
        created_at: now,
        details: { comment: "Automated GDPR deletion of supporting evidence" },
        updated_at: now,
        event_type: "gdpr_documents_deleted",
        public: true,
        does_not_constitute_update: true,
      }
    end

    def file_uploader
      @file_uploader ||= FileUpload::FileUploader.new
    end
  end
end
