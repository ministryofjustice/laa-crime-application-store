require "rails_helper"

RSpec.describe "Update submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  it "lets me update data by creating a new version" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
    expect(response).to have_http_status(:created)
    expect(submission.reload.current_version).to eq 2
    expect(submission.reload.latest_version.application).to eq({ "new" => "data" })
  end

  it "adds the event and updates last_updated_at" do
    submission = create(:submission, state: "sent_back", last_updated_at: 1.day.ago)

    freeze_time do
      patch "/v1/submissions/#{submission.id}",
            params: {
              application_state: "granted",
              events: [
                {
                  id: "123",
                  details: "foo",
                },
              ],
              application: { new: :data },
              json_schema_version: 1,
            }

      submission.reload
      expect(submission.events).to contain_exactly(hash_including("id" => "123", "details" => "foo"))
      expect(submission.state).to eq("granted")
      expect(submission.ordered_submission_versions.count).to eq(2)
      expect(submission.last_updated_at).to eql submission.events.first["created_at"].to_time
    end
  end

  context "with multiple events" do
    let(:events) do
      [
        {
          id: "123",
          details: "foo",
        },
        {
          id: "321",
          details: "bar",
        },
      ]
    end

    it "adds multiple events and updates last_updated_at" do
      submission = create(:submission, state: "sent_back", last_updated_at: 1.day.ago)

      freeze_time do
        patch "/v1/submissions/#{submission.id}",
              params: {
                application_state: "granted",
                events:,
                application: { new: :data },
                json_schema_version: 1,
              }

        submission.reload
        expect(submission.events)
          .to contain_exactly(
            hash_including("id" => "123", "details" => "foo"),
            hash_including("id" => "321", "details" => "bar"),
          )

        expect(submission.state).to eq("granted")
        expect(submission.ordered_submission_versions.count).to eq(2)
        expect(submission.last_updated_at).to eql(submission.events.first["created_at"].to_time)
      end
    end
  end

  it "does not allow overwriting events" do
    submission = create(:submission, events: [{ id: "A", details: "original version" }])
    patch "/v1/submissions/#{submission.id}",
          params: {
            application_state: "granted",
            events: [
              {
                id: "A",
                details: "rewriting history",
              },
            ],
            application: { new: :data },
            json_schema_version: 1,
          }

    submission.reload
    expect(submission.events.count).to eq 1
    expect(submission.events.first).to include(
      "details" => "original version",
    )
  end

  it "validates 'json_schema_version'" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: nil }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq("errors" => "Validation failed: Json schema version can't be blank")
  end

  it "validates 'application'" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: nil, json_schema_version: 1 }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq("errors" => "Validation failed: Application can't be blank")
  end

  context "when there is a subscriber" do
    let(:fixed_arbitrary_date) { Time.zone.local(2024, 11, 1, 10, 11, 12) }
    let(:submission) { create :submission }
    let(:webhook_url) { "https://webhook.example.com" }
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
        body: { submission_id: submission.id, data: expected_payload }.as_json,
      ).to_return(status: webhook_status)
    end

    let(:webhook_status) { 200 }

    let(:expected_payload) do
      submission.as_json.merge(
        application: { new: :data },
        application_state: "sent_back",
        version: 2,
        updated_at: Time.current.utc.as_json,
      )
    end

    let(:params) do
      {
        application_state: "sent_back",
        application: { new: :data },
        json_schema_version: 1,
      }
    end

    before do
      submission
      travel_to fixed_arbitrary_date
      create(:subscriber, subscriber_type: "provider", webhook_url:)
      token_stub
      webhook_stub
    end

    it "notifies them synchronously" do
      patch("/v1/submissions/#{submission.id}", params:)
      expect(webhook_stub).to have_been_requested
    end

    context "when the webhook fails" do
      let(:webhook_status) { 500 }

      it "cancels the entire update" do
        patch("/v1/submissions/#{submission.id}", params:)
        expect(response).to have_http_status :internal_server_error
        expect(submission.reload.state).to eq "submitted"
      end
    end
  end

  it "clears out pending versions" do
    submission = create(:submission)
    pending_version = create :submission_version, submission:, pending: true
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
    expect(submission.ordered_submission_versions.find_by(id: pending_version.id)).to be_nil
  end

  context "when provider is updating" do
    before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

    it "adds a new version event if appropriate" do
      submission = create(:submission, application_type: "crm7", state: :sent_back)
      patch "/v1/submissions/#{submission.id}", params: { application_state: "provider_updated", application: { new: :data }, json_schema_version: 1 }
      expect(response).to have_http_status(:created)
      expect(submission.reload.events.first).to include(
        "event_type" => "new_version",
      )
    end

    it "adds no new version event if not appropriate" do
      submission = create(:submission, application_type: "crm4", state: :sent_back)
      patch "/v1/submissions/#{submission.id}", params: { application_state: "provider_updated", application: { new: :data }, json_schema_version: 1 }
      expect(response).to have_http_status(:created)
      expect(submission.reload.events.count).to eq 0
    end
  end
end
