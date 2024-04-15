class NotifySubscriber < ApplicationJob
  ClientResponseError = Class.new(StandardError)
  retry_on ClientResponseError, wait: :polynomially_longer, attempts: 10

  def perform(subscriber_id, submission_id)
    subscriber = Subscriber.find(subscriber_id)

    response = HTTParty.post(
      subscriber.webhook_url,
      headers:,
      body: {
        submission_id:,
      }.to_json,
    )

    return if response.code == 200

    subscriber.with_lock do
      subscriber.failed_attempts += 1
      subscriber.save!
    end

    return if delete_subscriber(subscriber)

    raise ClientResponseError, "Failed to notify subscriber about #{submission_id} - #{subscriber.webhook_url} returned #{response.code}"
  end

  def delete_subscriber(subscriber)
    deletion_threshold = ENV["SUBSCRIBER_FAILED_ATTEMPT_DELETION_THRESHOLD"]

    return unless deletion_threshold&.to_i&.positive? && deletion_threshold.to_i <= subscriber.failed_attempts

    subscriber.destroy!
  end

  def headers
    basic = { "Content-Type" => "application/json" }

    return basic unless Tokens::GenerationService.authentication_required?

    basic.merge(
      "Authorization" => "Bearer #{Tokens::GenerationService.call}",
    )
  end
end
