class NotifySubscriber < ApplicationJob
  ClientResponseError = Class.new(StandardError)

  def self.perform_later(subscriber_id, submission)
    # If there is a Redis problem and we cannot enqueue the job,
    # this flag will at least mean that we identify which records
    # are going to need syncing to provider/caseworker so we
    # can re-attain consistency
    submission.update!(notify_subscriber_completed: false)
    super
  end

  def perform(subscriber_id, submission)
    raise_error = false
    subscriber = Subscriber.find(subscriber_id)
    raise_error = handle_failure(subscriber) unless send_message_to_webhook(subscriber.webhook_url, submission)

    submission.update!(notify_subscriber_completed: true)
    raise ClientResponseError, "Failed to notify subscriber about #{submission.id} - #{subscriber.webhook_url} returned error" if raise_error
  end

  def handle_failure(subscriber)
    subscriber.failed_attempts += 1
    subscriber.save!

    !delete_subscriber(subscriber)
  end

  def send_message_to_webhook(webhook_url, submission)
    response = HTTParty.post(
      webhook_url,
      headers:,
      body: {
        submission_id: submission.id,
        data: submission,
      }.to_json,
    )

    response.code == 200
  rescue Socket::ResolutionError
    # If the subscriber web app has been taken fully offline and its DNS removed, this will fire
    false
  end

  def delete_subscriber(subscriber)
    deletion_threshold = ENV.fetch("SUBSCRIBER_FAILED_ATTEMPT_DELETION_THRESHOLD", nil)

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
