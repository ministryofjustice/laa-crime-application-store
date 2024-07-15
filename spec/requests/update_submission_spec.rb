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
    submission = create(:submission, application_state: "further_info", last_updated_at: 1.day.ago)

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
      expect(submission.application_state).to eq("granted")
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
      submission = create(:submission, application_state: "further_info", last_updated_at: 1.day.ago)

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

        expect(submission.application_state).to eq("granted")
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

  it "enqueues a notification to subscribers" do
    submission = create(:submission)
    create(:subscriber, subscriber_type: "provider")

    params = {
      application_state: "sent_back",
      application: { new: :data },
      json_schema_version: 1,
    }
    expect { patch("/v1/submissions/#{submission.id}", params:) }.to have_enqueued_job
  end
end
