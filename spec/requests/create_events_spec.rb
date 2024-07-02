require "rails_helper"

RSpec.describe "Create events" do
  context "when authenticated with bearer token" do
    let(:submission) { create(:submission, application_state:) }
    let(:application_state) { "submitted" }

    before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

    it "saves what I send" do
      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
          },
        ],
      }
      expect(response).to have_http_status :created

      expect(submission.reload.events).to match([
        {
          "created_at" => an_instance_of(String),
          "details" => "history",
          "id" => "A",
          "submission_version" => 1,
          "updated_at" => an_instance_of(String),
        },
      ])
    end

    it "does not overwrite existing events" do
      submission.update!(events: [{ id: "A", details: "actual history" }])
      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
          },
        ],
      }
      expect(response).to have_http_status :created
      expect(submission.reload.events).to match([
        {
          "id" => "A",
          "details" => "actual history",
        },
      ])
    end

    it "does not increament the version" do
      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
          },
        ],
      }
      expect(response).to have_http_status :created
      expect(submission.reload.current_version).to eq(1)
    end

    it "not not allow update of application_state" do
      post "/v1/submissions/#{submission.id}/events", params: {
        application_state: "granted",
        events: [
          {
            id: "A",
            details: "history",
          },
        ],
      }
      expect(response).to have_http_status :created
      expect(submission.reload.application_state).to eq("submitted")
    end
  end
end
