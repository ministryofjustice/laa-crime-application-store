class NoteService
  class << self
    def call(params)
      submission = Submission.find_by(application_id: params[:id])
      submission.events << Event.new(
        event_type: "note",
        submission_version: submission.current_version,
        primary_user_id: params[:user_id],
        details: {
          comment: params[:note],
        },
      )
      submission.save!
    end
  end
end
