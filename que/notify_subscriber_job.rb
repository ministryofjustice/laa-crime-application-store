# frozen_string_literal: true

require './token_provider'

# This job attempts to notify a subscriber about a new or updated submission
class NotifySubscriberJob < Que::Job
  def run(url, submission_id)
    headers = if TokenProvider.instance.authentication_configured?
                { authorization: "Bearer #{TokenProvider.instance.bearer_token}" }
              else
                {}
              end

    response = HTTParty.post(url, headers:, body: { submission_id: })

    raise "Unexpected response from subscriber - status #{response.code}" unless response.code == 200
  end
end
