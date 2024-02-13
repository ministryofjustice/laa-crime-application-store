class RiskChangeService
  class << self
    def call(params)
      submission = Submission.find_by(application_id: params[:id])
      Submission.transaction do
        submission.events << Event.new(
          event_type: "change_risk",
          submission_version: submission.current_version,
          primary_user_id: params[:user_id],
          details: {
            field: "risk",
            from: submission.application_risk,
            to: params[:application_risk],
            comment: params[:comment],
          },
        )
        submission.update!(application_risk: params[:application_risk])
      end
    end
  end
end
