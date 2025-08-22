require "rails_helper"

RSpec.describe "Update submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  context "with ability to send emails (nsm)" do
    before do
      allow(ENV).to receive(:fetch).with("SEND_EMAILS", "false").and_return("true")
      allow(Nsm::SubmissionMailer).to receive_message_chain(:notify, :deliver_now!).and_return(true)
    end

    it "sends email notification on update" do
      submission = create(:submission, :with_nsm_version)
      patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
      expect(response).to have_http_status(:created)
    end
  end

  context "with ability to send emails (pa)" do
    before do
      allow(ENV).to receive(:fetch).with("SEND_EMAILS", "false").and_return("true")
      allow(PriorAuthority::SubmissionMailer).to receive_message_chain(:notify, :deliver_now!).and_return(true)
    end

    it "sends email notification on update" do
      submission = create(:submission, :with_pa_version)
      patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
      expect(response).to have_http_status(:created)
    end
  end

  it "lets me update data by creating a new version with laa reference same as first version" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
    expect(response).to have_http_status(:created)
    expect(submission.reload.current_version).to eq 2
    expect(submission.reload.latest_version.application).to eq(
      {
        "new" => "data",
        "laa_reference" => "LAA-123456",
      },
    )
    expect(submission.reload.latest_version.application["laa_reference"]).to eq("LAA-123456")
  end

  it "fails when laa reference is not present in first version" do
    submission = create(:submission, build_scope: [:with_no_laa_reference])
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
    expect(response).to have_http_status(:unprocessable_entity)
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
