class SubmissionCreationService
  class << self
    def call(params)
      Submission.transaction do
        submission = Submission.create!(initial_data(params))
        submission.submission_versions.create!(
          json_schema_version: params[:json_schema_version],
          data: params[:application],
        )
      end
    end

    def initial_data(params)
      params.permit(%i[application_type application_risk application_id])
            .merge(application_state: "submitted",
                   events: [Event.new(event_type: "new_version")])
    end
  end
end
