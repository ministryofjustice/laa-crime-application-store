class NotifySubscriber < ApplicationJob
  ClientResponseError = Class.new(StandardError)
  retry_on ClientResponseError, wait: :polynomially_longer, attempts: 10

  def perform(webhook_url, submission_id)
    response = HTTParty.post(
      webhook_url,
      headers:,
      body: {
        submission_id:,
      }.to_json,
    )

    return if response.code == 200

    raise ClientResponseError, "Failed to notify subscriber about #{submission_id} - #{webhook_url} returned #{response.code}"
  end

  def headers
    basic = { "Content-Type" => "application/json" }

    return basic unless Tokens::GenerationService.authentication_required?

    basic.merge(
      "Authorization" => "Bearer #{Tokens::GenerationService.call}",
    )
  end
end
