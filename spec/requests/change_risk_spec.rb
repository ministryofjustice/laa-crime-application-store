require "rails_helper"

RSpec.describe "Change submission risk" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "updates the risk" do
    submission = create :submission, application_risk: "low"
    post "/v1/submissions/#{submission.application_id}/risk_changes", params: { application_risk: "medium" }
    expect(response).to have_http_status(:ok)
    expect(submission.reload.application_risk).to eq "medium"
  end

  it "adds an event" do
    submission = create :submission, application_risk: "low"
    post "/v1/submissions/#{submission.application_id}/risk_changes", params: { application_risk: "medium", user_id: "999", comment: "cos" }
    expect(submission.reload.events.first).to include(
      "event_type" => "change_risk",
      "primary_user_id" => "999",
      "details" => {
        "field" => "risk",
        "from" => "low",
        "to" => "medium",
        "comment" => "cos",
      },
    )
  end
end
