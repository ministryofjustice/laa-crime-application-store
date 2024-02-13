class AdjustmentService
  class << self
    def call(params)
      submission = Submission.find_by(application_id: params[:id])
      Submission.transaction do
        add_events(submission, params)
        submission.save!
        submission.submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          data: params[:application],
        )
      end
    end

    def add_events(submission, params)
      params[:change_detail_sets]&.each do |details|
        submission.events << Event.new(
          event_type: "edit",
          submission_version: submission.current_version_number,
          primary_user_id: params[:user_id],
          linked_type: params[:linked_type],
          linked_id: params[:linked_id],
          details:,
        )
      end
    end
  end
end
