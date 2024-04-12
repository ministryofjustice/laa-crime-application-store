require "rails_helper"

RSpec.describe "Update submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(true) }

  it "lets me update data by creating a new version" do
    submission = create :submission
    patch "/v1/submissions/#{submission.id}", params: { application: { new: :data }, json_schema_version: 1 }
    expect(response).to have_http_status(:created)
    expect(submission.reload.current_version).to eq 2
    expect(submission.reload.latest_version.application).to eq({ "new" => "data" })
  end

  it "updates events" do
    submission = create :submission
    patch "/v1/submissions/#{submission.id}",
          params: {
            events: [
              {
                event_type: "edit",
                details: "foo",
              },
            ],
          }

    expect(submission.reload.events.count).to eq 1
    expect(submission.reload.events.first).to include(
      "event_type" => "edit",
      "details" => "foo",
    )
  end

  it "updates metadata" do
    submission = create :submission
    patch "/v1/submissions/#{submission.id}",
          params: {
            application_state: "sent_back",
            application_risk: "medium-rare",
          }

    expect(submission.reload.application_state).to eq "sent_back"
    expect(submission.application_risk).to eq "medium-rare"
  end

  it "validates" do
    submission = create :submission
    patch "/v1/submissions/#{submission.id}", params: { application: { new: :data }, json_schema_version: nil }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "triggers a notification to subscribers" do
    submission = create :submission
    subscriber = create :subscriber

    expect(HTTParty).to receive(:post).with(
      subscriber.webhook_url,
      headers: { "Content-Type" => "application/json" },
      body: { submission_id: submission.id },
    )

    patch "/v1/submissions/#{submission.id}",
          params: {
            application_state: "sent_back",
            application_risk: "medium-rare",
          }
  end
end
