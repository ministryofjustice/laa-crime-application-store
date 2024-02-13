class StateChangeService
  SEND_BACK_STATES = %w[further_info provider_requested].freeze
  ASSESSED_STATES = %w[granted part_grant rejected].freeze

  class << self
    def call(params)
      submission = Submission.find_by(application_id: params[:id])
      Submission.transaction do
        submission.events << Event.new(
          state_specific_fields(params[:application_state]).merge(
            submission_version: submission.current_version,
            primary_user_id: params[:user_id],
            details: {
              field: "state",
              from: submission.application_state,
              to: params[:application_state],
              comment: params[:comment],
            },
          ),
        )
        submission.update!(application_state: params[:application_state])
      end
    end

    def state_specific_fields(state)
      if ASSESSED_STATES.include?(state)
        { event_type: "decision", public: true }
      elsif SEND_BACK_STATES.include?(state)
        { event_type: "send_back", public: false }
      else
        raise "Unknown state"
      end
    end
  end
end
