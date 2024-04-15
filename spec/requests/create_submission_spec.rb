require "rails_helper"

RSpec.describe "Create submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

  let(:created_record) { Submission.last }

  it "saves what I send" do
    id = SecureRandom.uuid
    post "/v1/submissions", params: {
      application_id: id,
      application_type: "crm4",
      application_risk: "low",
      json_schema_version: 1,
      application: { foo: :bar },
    }
    expect(response).to have_http_status :created

    expect(created_record).to have_attributes(
      id:,
      application_state: "submitted",
      application_type: "crm4",
      application_risk: "low",
      current_version: 1,
    )

    expect(created_record.latest_version).to have_attributes(
      json_schema_version: 1,
      application: { "foo" => "bar" },
    )
  end

  it "validates what I send" do
    post "/v1/submissions", params: {
      application_id: SecureRandom.uuid,
    }
    expect(response).to have_http_status :unprocessable_entity
  end

  it "detects conflicting information" do
    submission = create(:submission)
    post "/v1/submissions", params: {
      application_id: submission.id,
    }
    expect(response).to have_http_status :conflict
  end

  context "when webhook authentication is not required" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV["AUTHENTICATION_REQUIRED"] = nil
    end

    it "triggers a notification to subscribers" do
      id = SecureRandom.uuid
      subscriber = create :subscriber

      expect(HTTParty).to receive(:post).with(
        subscriber.webhook_url,
        headers: { "Content-Type" => "application/json" },
        body: { submission_id: id },
      )

      post "/v1/submissions", params: {
        application_id: id,
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }
    end

    it "does not trigger for subscribers matching role of client" do
      create :subscriber, subscriber_type: "provider"

      expect(HTTParty).not_to receive(:post)

      post "/v1/submissions", params: {
        application_id: SecureRandom.uuid,
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }
    end
  end

  context "when webhook authentication is required" do
    around do |example|
      ENV["TENANT_ID"] = "123"
      example.run
      ENV["TENANT_ID"] = nil
    end

    it "makes a single call to get a token" do
      stub = stub_request(:post, %r{https.*/oauth2/v2.0/token}).to_return(
        status: 200,
        body: '{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":3600,"created_at":1582809000}',
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )

      id = SecureRandom.uuid
      subscriber_1 = create :subscriber, subscriber_type: "caseworker", webhook_url: "a"
      subscriber_2 = create :subscriber, subscriber_type: "caseworker", webhook_url: "b"

      expect(HTTParty).to receive(:post).once.with(
        subscriber_2.webhook_url,
        headers: { "Content-Type" => "application/json", "Authorization" => "Bearer test-bearer-token" },
        body: { submission_id: id },
      )

      expect(HTTParty).to receive(:post).once.with(
        subscriber_1.webhook_url,
        headers: { "Content-Type" => "application/json", "Authorization" => "Bearer test-bearer-token" },
        body: { submission_id: id },
      )

      post "/v1/submissions", params: {
        application_id: id,
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect(stub).to have_been_requested.once
    end
  end
end
