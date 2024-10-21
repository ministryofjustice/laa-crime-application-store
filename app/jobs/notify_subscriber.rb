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
    unless send_message_to_webhook(subscriber.webhook_url, submission)
      raise_error = handle_failure_maybe_raise(subscriber)
    end

    submission.update!(notify_subscriber_completed: true)
    raise ClientResponseError, "Failed to notify subscriber about #{submission.id} - #{subscriber.webhook_url} returned error" if raise_error
  end

  def handle_failure_maybe_raise(subscriber)
    subscriber.failed_attempts += 1
    subscriber.save!

    subscriber_deleted = delete_subscriber(subscriber)

    # If we have just deleted the subscriber, we do not want to raise the error,
    # because that will prompt the job to be retried, and retrying cannot work if the subscriber
    #  has been deleted
    !subscriber_deleted
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
  rescue Socket::ResolutionError, Net::OpenTimeout, Errno::ECONNREFUSED
    # These errors could be a sign that a client web app has been taken offline, so we
    # want to catch them in order to run `handle_failure`
    false
  end

  # Returns a boolean indicating whether the subscriber has been deleted.
  def delete_subscriber(subscriber)
    deletion_threshold = ENV.fetch("SUBSCRIBER_FAILED_ATTEMPT_DELETION_THRESHOLD", nil)

    return false unless deletion_threshold&.to_i&.positive? && deletion_threshold.to_i <= subscriber.failed_attempts

    subscriber.destroy!
    true
  end

  def headers
    basic = { "Content-Type" => "application/json" }

    return basic unless Tokens::GenerationService.authentication_required?

    basic.merge(
      "Authorization" => "Bearer #{Tokens::GenerationService.call}",
    )
  end
end
