module Authorization
  module Rules
    PERMISSIONS = {
      provider: {
        subscribers: {
          create: true,
          destroy: ->(object, _) { !object || object.subscriber_type == "provider" },
        },
        submissions: {
          index: true,
          show: true,
          create: ->(_, params) { params[:application_state].in?(PERMITTED_INITIAL_SUBMISSION_STATES) },
          update: ->(object, params) { state_pair_allowed?(object, params, PERMITTED_SUBMISSION_STATE_CHANGES[:provider]) },
        },
      },
      caseworker: {
        subscribers: {
          create: true,
          destroy: ->(object, _) { !object || object.subscriber_type == "caseworker" },
        },
        submissions: {
          index: true,
          show: true,
          update: ->(object, params) { state_pair_allowed?(object, params, PERMITTED_SUBMISSION_STATE_CHANGES[:caseworker]) },
        },
        events: {
          create: ->(object, _params) { object.application_state.in?(%w[submitted provider_updated]) },
        },
        searches: {
          create: true,
        },
      },
    }.freeze

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
                   provider_requested
                   sent_back],
        },
        { pre: %w[sent_back provider_requested], post: %w[granted part_grant rejected] },
      ],
    }.freeze

    PERMITTED_INITIAL_SUBMISSION_STATES = %w[submitted].freeze

    def self.state_pair_allowed?(object, params, pairs)
      pairs.any? do |pair|
        object.application_state.in?(pair[:pre]) && params[:application_state].in?(pair[:post])
      end
    end
  end
end
