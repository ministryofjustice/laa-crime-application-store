class NotifySubscriber < ApplicationJob
  def perform(webhook_url, submission_id)
    HTTParty.post(
      webhook_url,
      headers:,
      body: {
        submission_id:,
      },
    )
  end

  def headers
    basic = { "Content-Type" => "application/json" }

    return basic unless Tokens::GenerationService.authentication_required?

    basic.merge(
      "Authorization" => "Bearer #{Tokens::GenerationService.call}",
    )
  end
end
