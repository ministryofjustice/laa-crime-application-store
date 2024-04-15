require "rails_helper"

RSpec.describe NotifySubscriber do
  subject(:job) { described_class.new }

  let(:webhook_url) { "https://example.com/webhook" }
  let(:submission_id) { "123" }

  context "when webhook authentication is not required" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV["AUTHENTICATION_REQUIRED"] = nil
    end

    it "triggers a notification to subscribers" do
      stub = stub_request(:post, webhook_url).with(
        body: { submission_id: },
      ).to_return(status: 200)

      job.perform(webhook_url, submission_id)
      expect(stub).to have_been_requested
    end

    it "raises an error if a non-200 status is requested" do
      stub_request(:post, webhook_url).with(
        body: { submission_id: },
      ).to_return(status: 503)

      expect { job.perform(webhook_url, submission_id) }.to raise_error NotifySubscriber::ClientResponseError
    end
  end

  context "when webhook authentication is required" do
    around do |example|
      ENV["TENANT_ID"] = "123"
      example.run
      ENV["TENANT_ID"] = nil
    end

    # Reset class instance variables between tests
    before do
      Tokens::GenerationService.instance_variable_set(:@access_token, nil)
    end

    let(:token_stub) do
      stub_request(:post, %r{https.*/oauth2/v2.0/token}).to_return(
        status: 200,
        body: '{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":3600,"created_at":1582809000}',
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
    end

    let(:webhook_stub) do
      stub_request(:post, webhook_url).with(
        headers: { "Content-Type" => "application/json", "Authorization" => "Bearer test-bearer-token" },
        body: { submission_id: },
      ).to_return(status: 200)
    end

    it "makes a call to get a token" do
      token_stub
      webhook_stub

      job.perform(webhook_url, submission_id)

      expect(token_stub).to have_been_requested
      expect(webhook_stub).to have_been_requested
    end

    it "only makes once call even if the job runs multiple times" do
      token_stub
      webhook_stub

      2.times { job.perform(webhook_url, submission_id) }

      expect(token_stub).to have_been_requested.once
    end
  end
end
