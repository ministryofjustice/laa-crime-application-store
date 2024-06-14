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

  it "updates events" do
    submission = create(:submission, application_state: "further_info")
    patch "/v1/submissions/#{submission.id}",
          params: {
            application_state: "granted",
            events: [
              {
                id: "123",
                details: "foo",
              },
            ],
          }

    expect(submission.reload.events.count).to eq 1
    expect(submission.reload.events.first).to include(
      "id" => "123",
      "details" => "foo",
    )
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
          }

    expect(submission.reload.events.count).to eq 1
    expect(submission.reload.events.first).to include(
      "details" => "original version",
    )
  end

  it "updates metadata" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}",
          params: {
            application_state: "sent_back",
            application_risk: "medium-rare",
          }

    expect(submission.reload.application_state).to eq "sent_back"
    expect(submission.application_risk).to eq "medium-rare"
  end

  it "validates" do
    submission = create(:submission)
    patch "/v1/submissions/#{submission.id}", params: { application_state: "granted", application: { new: :data }, json_schema_version: nil }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "enqueues a notification to subscribers" do
    submission = create(:submission)
    create(:subscriber, subscriber_type: "provider")

    params = {
      application_state: "sent_back",
      application_risk: "medium-rare",
    }
    expect { patch("/v1/submissions/#{submission.id}", params:) }.to have_enqueued_job
  end
end
