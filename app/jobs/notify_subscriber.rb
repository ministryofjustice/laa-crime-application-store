class NotifySubscriber < ApplicationJob
  ClientResponseError = Class.new(StandardError)

  def self.perform_later(subscriber_id, submission)
    submission.update!(notify_subscriber_completed: false)
    super(subscriber_id, submission.id)
  end

  def perform(subscriber_id, submission_id)
    raise_error = false
    subscriber = Subscriber.find(subscriber_id)
    submission = Submission.find(submission_id)
    # This lock is important because it forces the job to wait until
    # the locked transaction that enqueued this job is released,
    # ensuring that when this job runs it is working with fresh
    # data
    submission.with_lock do
      raise_error = handle_failure(subscriber) unless send_message_to_webhook(subscriber.webhook_url, submission)

      submission.update!(notify_subscriber_completed: false)
    end

    raise ClientResponseError, "Failed to notify subscriber about #{submission_id} - #{subscriber.webhook_url} returned error" if raise_error
  end

  def handle_failure(subscriber)
    subscriber.failed_attempts += 1
    subscriber.save!

    return false if delete_subscriber(subscriber)

    true
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
