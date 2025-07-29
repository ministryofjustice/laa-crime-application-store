module Authorization
  module Rules
    PERMISSIONS = {
      provider: {
        submissions: {
          index: true,
          show: true,
          create: ->(_, params) { params[:application_state].in?(PERMITTED_INITIAL_SUBMISSION_STATES) },
          update: ->(object, params) { state_pair_allowed?(object, params, PERMITTED_SUBMISSION_STATE_CHANGES[:provider]) },
        },
        searches: {
          create: true,
        },
        failed_imports: {
          create: true,
          show: true,
        },
      },
      caseworker: {
        submissions: {
          index: true,
          show: true,
          metadata: true,
          update: ->(object, params) { state_pair_allowed?(object, params, PERMITTED_SUBMISSION_STATE_CHANGES[:caseworker]) },
          auto_assignments: true,
        },
        payment_requests: {
          create: true,
          update: true,
          link: ->(object, _params) { object&.submitted_at.nil? },
        },
        events: {
          create: ->(object, _params) { object.state.in?(EDITABLE_BY_CASEWORKER_STATES) },
        },
        assignments: {
          create: true,
          destroy: true,
        },
        searches: {
          create: true,
        },
        adjustments: {
          create: ->(object, _params) { object.state.in?(EDITABLE_BY_CASEWORKER_STATES) },
        },
      },
    }.freeze

    # Pre-RFI NSM claims are editable in the sent-back state.
    EDITABLE_BY_CASEWORKER_STATES = %w[submitted sent_back provider_updated].freeze

    PERMITTED_SUBMISSION_STATE_CHANGES = {
      provider: [
        { pre: %w[sent_back], post: %w[provider_updated] },
      ],
      caseworker: [
        { pre: %w[sent_back], post: %w[expired] },
        {
          pre: %w[submitted provider_updated],
          post: %w[granted
                   auto_grant
                   part_grant
                   rejected
                   sent_back],
        },
        { pre: %w[sent_back], post: %w[granted part_grant rejected] },
      ],
    }.freeze

    PERMITTED_INITIAL_SUBMISSION_STATES = %w[submitted].freeze

    def self.state_pair_allowed?(object, params, pairs)
      pairs.any? do |pair|
        object.state.in?(pair[:pre]) && params[:application_state].in?(pair[:post])
      end
    end
  end
end
