class UnassignmentService
  class << self
    def call(params)
      submission = Submission.find_by(application_id: params[:id])
      return false if submission.assigned_user_id.nil?

      submission.unassigned_user_ids << submission.assigned_user_id
      submission.events << Event.new(
        event_type: "unassignment",
        primary_user_id: submission.assigned_user_id,
        secondary_user_id: submission.assigned_user_id == params[:user_id] ? nil : params[:user_id],
        submission_version: submission.current_version_number,
        details: {
          comment: params[:comment],
        },
      )
      submission.update!(assigned_user_id: nil)

      true
    end
  end
end
