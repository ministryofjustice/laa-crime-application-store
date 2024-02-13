require "rails_helper"

RSpec.describe "Delete assignment" do
  before { allow(AuthenticationService).to receive(:call).and_return(true) }

  it "lets me unassign a user" do
    submission = create :submission, assigned_user_id: "123"
    delete "/v1/submissions/#{submission.application_id}/assignment", params: { user_id: "123", comment: "because" }
    expect(response).to have_http_status(:ok)
    expect(submission.reload.assigned_user_id).to be_nil
    expect(submission.reload.unassigned_user_ids).to eq(%w[123])
  end

  it "saves metadata" do
    submission = create :submission, assigned_user_id: "123"
    delete "/v1/submissions/#{submission.application_id}/assignment", params: { user_id: "456", comment: "because" }
    expect(response).to have_http_status(:ok)
    expect(submission.reload.assigned_user_id).to be_nil
    expect(submission.events.first).to include(
      "event_type" => "unassignment",
      "details" => { "comment" => "because" },
      "secondary_user_id" => "456",
      "primary_user_id" => "123",
    )
    expect(submission.unassigned_user_ids).to eq(%w[123])
  end

  it "fails out if there is no assigned user" do
    submission = create :submission, assigned_user_id: nil
    delete "/v1/submissions/#{submission.application_id}/assignment"
    expect(response).to have_http_status(:bad_request)
  end
end
