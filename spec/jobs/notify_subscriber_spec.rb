require "rails_helper"

RSpec.describe NotifySubscriber do
  subject(:job) { described_class.new }

  let(:subscriber) { create(:subscriber, webhook_url: "https://example.com/webhook") }
  let(:submission) { create(:submission, notify_subscriber_completed: nil) }

  describe ".perform_later" do
    it "sets a flag" do
      described_class.perform_later(subscriber.id, submission)
      expect(submission.reload.notify_subscriber_completed).to be false
    end
  end

  context "when webhook authentication is not required" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV["AUTHENTICATION_REQUIRED"] = nil
    end

    it "triggers a notification to subscribers" do
      stub = stub_request(:post, subscriber.webhook_url).with(
        body: { submission_id: submission.id, data: submission.as_json },
      ).to_return(status: 200)

      job.perform(subscriber.id, submission)
      expect(stub).to have_been_requested
    end

    context "when the job fails due to client experiencing error" do
      before do
        stub_request(:post, subscriber.webhook_url).with(
          body: { submission_id: submission.id, data: submission.as_json },
        ).to_return(status: 503)
      end

      it "raises an error if a non-200 status is returned" do
        expect { job.perform(subscriber.id, submission) }.to raise_error NotifySubscriber::ClientResponseError
      end

      it "bumps the failed_attempts count" do
        expect {
          begin
            job.perform(subscriber.id, submission)
          rescue NotifySubscriber::ClientResponseError
            nil
          end
        }.to change { subscriber.reload.failed_attempts }.from(0).to(1)
      end

      context "when deletion on failure is configured" do
        around do |example|
          ENV["SUBSCRIBER_FAILED_ATTEMPT_DELETION_THRESHOLD"] = "2"
          example.run
          ENV["SUBSCRIBER_FAILED_ATTEMPT_DELETION_THRESHOLD"] = nil
        end

        context "when the subscriber was almost at the threshold" do
          before { subscriber.update(failed_attempts: 1) }

          it "raises no error" do
            expect { job.perform(subscriber.id, submission) }.not_to raise_error
          end

          it "deletes the subscriber" do
            job.perform(subscriber.id, submission)
            expect(Subscriber.find_by(id: subscriber.id)).to be_nil
          end
        end
      end
    end

    context "when the job fails due to client no longer existing" do
      before do
        allow(HTTParty).to receive(:post).and_raise(Socket::ResolutionError)
      end

      it "raises an appropriate error" do
        expect { job.perform(subscriber.id, submission) }.to raise_error NotifySubscriber::ClientResponseError
      end
    end
  end

  context "when webhook authentication is required" do
    around do |example|
      ENV["TENANT_ID"] = "123"
      example.run
      ENV["TENANT_ID"] = nil
    end

    # Reset class instance variables between tests, and keep timestamps stable
    before do
      Tokens::GenerationService.instance_variable_set(:@access_token, nil)
      travel_to 1.day.ago
    end

    let(:token_stub) do
      stub_request(:post, %r{https.*/oauth2/v2.0/token}).to_return(
        status: 200,
        body: '{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":3600,"created_at":1582809000}',
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
    end

    let(:webhook_stub) do
      stub_request(:post, subscriber.webhook_url).with(
        headers: { "Content-Type" => "application/json", "Authorization" => "Bearer test-bearer-token" },
        body: { submission_id: submission.id, data: submission }.as_json,
      ).to_return(status: 200)
    end

    it "makes a call to get a token" do
      token_stub
      webhook_stub

      job.perform(subscriber.id, submission)

      expect(token_stub).to have_been_requested
      expect(webhook_stub).to have_been_requested
    end

    it "only makes once call even if the job runs multiple times" do
      token_stub
      webhook_stub

      2.times { job.perform(subscriber.id, submission) }

      expect(token_stub).to have_been_requested.once
    end
  end
end
