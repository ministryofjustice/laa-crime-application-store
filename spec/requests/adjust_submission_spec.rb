require "rails_helper"

RSpec.describe "Adjust submission" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  let(:submission) { create(:submission) }

  it "validates" do
    post "/v1/submissions/#{submission.id}/adjustments", params: {}
    expect(response).to have_http_status(:unprocessable_entity)
  end

  context "when there is no pending version" do
    it "adds a new pending version" do
      post "/v1/submissions/#{submission.id}/adjustments", params: { application: { new: :data } }
      expect(response).to have_http_status(:created)
      expect(submission.reload.current_version).to eq 1
      expect(submission.latest_version).to have_attributes(
        application: { "new" => "data" },
        version: 2,
      )
    end
  end

  context "when there is a pending version" do
    let(:pending_version) { create(:submission_version, submission:, application: { "old" => "data" }, pending: true) }

    before { pending_version }

    it "replaces the pending version data" do
      post "/v1/submissions/#{submission.id}/adjustments", params: { application: { new: :data } }
      expect(response).to have_http_status(:created)
      expect(pending_version.reload).to have_attributes(
        application: { "new" => "data" },
      )
    end
  end
end
