# frozen_string_literal: true

require "./token_provider"

# This job attempts to notify a subscriber about a new or updated submission
class NotifySubscriberJob < Que::Job
  RecipientError = Class.new(StandardError)
  def run(url, submission_id)
    headers = if TokenProvider.instance.authentication_configured?
                { authorization: "Bearer #{TokenProvider.instance.bearer_token}" }
              else
                {}
              end

    response = HTTParty.post(url, headers:, body: { submission_id: })

    raise RecipientError, "Unexpected response from subscriber - status #{response.code}" unless response.code == 200
  end

  def handle_error(error)
    case error
    when RecipientError
      super
      error_count > 5 # The return value of this method determines whether the error notifier proc is triggered
    else
      super
    end
  end
end
