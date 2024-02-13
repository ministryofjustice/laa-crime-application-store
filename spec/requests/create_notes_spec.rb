require "rails_helper"

RSpec.describe "Create note" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "updates the risk" do
    submission = create :submission, application_risk: "low"
    post "/v1/submissions/#{submission.application_id}/notes", params: { user_id: "123", note: "Hello" }
    expect(response).to have_http_status(:created)
    expect(submission.reload.events.first).to include(
      "event_type" => "note",
      "primary_user_id" => "123",
      "details" => {
        "comment" => "Hello",
      },
    )
  end
end
