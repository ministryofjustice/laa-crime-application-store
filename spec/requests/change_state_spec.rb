require "rails_helper"

RSpec.describe "Change submission state" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "updates the state" do
    submission = create :submission, application_state: "submitted"
    post "/v1/submissions/#{submission.application_id}/state_changes", params: { application_state: "granted" }
    expect(response).to have_http_status(:ok)
    expect(submission.reload.application_state).to eq "granted"
  end

  it "adds an event" do
    submission = create :submission, application_state: "submitted"
    post "/v1/submissions/#{submission.application_id}/state_changes",
         params: { application_state: "provider_requested", user_id: "999", comment: "dunno why" }
    expect(submission.reload.events.first).to include(
      "event_type" => "send_back",
      "primary_user_id" => "999",
      "details" => {
        "field" => "state",
        "from" => "submitted",
        "to" => "provider_requested",
        "comment" => "dunno why",
      },
    )
  end

  it "validates" do
    submission = create :submission
    post "/v1/submissions/#{submission.application_id}/state_changes", params: { application_state: "unknown" }
    expect(response).to have_http_status :unprocessable_entity
  end
end
