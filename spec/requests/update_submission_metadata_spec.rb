require "rails_helper"

RSpec.describe "Update submission metadata" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role:) }

  context "when I am a caseworker" do
    let(:role) { :caseworker }

    it "lets me update the application risk" do
      submission = create(:submission, application_risk: "low")
      patch "/v1/submissions/#{submission.id}/metadata", params: { application_risk: "high" }
      expect(response).to have_http_status(:ok)
      expect(submission.reload.current_version).to eq 1
      expect(submission.application_risk).to eq("high")
    end

    it "adds an event and bumps last updated at" do
      event_date = Time.zone.local(2024, 9, 1, 10, 30)
      submission = create(:submission, application_risk: "low")
      patch "/v1/submissions/#{submission.id}/metadata",
            params: { events: [{ id: "1", details: "2", created_at: event_date }] }
      expect(response).to have_http_status(:ok)
      expect(submission.reload.events).to contain_exactly(
        hash_including("id" => "1", "details" => "2"),
      )
      expect(submission.last_updated_at).to eq event_date
    end

    it "validates" do
      submission = create(:submission, application_risk: "low")
      allow(Submissions::MetadataUpdateService).to receive(:call).and_raise(ActiveRecord::RecordInvalid)
      patch "/v1/submissions/#{submission.id}/metadata", params: { application_risk: "high" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(submission.application_risk).to eq("low")
    end
  end

  context "when I am a provider" do
    let(:role) { :provider }

    it "does not let me update the application risk" do
      submission = create(:submission, application_risk: "high")
      patch "/v1/submissions/#{submission.id}/metadata", params: { application_risk: "low" }
      expect(response).to have_http_status(:forbidden)
      expect(submission.reload.application_risk).to eq("high")
    end
  end
end
