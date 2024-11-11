require "rails_helper"

RSpec.describe "Create events" do
  context "when authenticated with bearer token" do
    let(:submission) { create(:submission, state:, last_updated_at: old_timestamp) }
    let(:state) { "submitted" }
    let(:old_timestamp) { 3.days.ago }

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

    it "not not allow update of state" do
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
      expect(submission.reload.state).to eq("submitted")
    end

    it "bumps last updated at to implicit timestamp" do
      freeze_time

      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
          },
        ],
      }
      expect(response).to have_http_status :created

      expect(submission.reload.last_updated_at).to eq Time.current
    end

    it "bumps last updated at to explicit timestamp" do
      freeze_time

      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
            created_at: 2.hours.ago,
          },
        ],
      }
      expect(response).to have_http_status :created

      expect(submission.reload.last_updated_at).to eq 2.hours.ago
    end

    it "ignores timestamps if commandeed" do
      freeze_time

      post "/v1/submissions/#{submission.id}/events", params: {
        events: [
          {
            id: "A",
            details: "history",
            created_at: 2.hours.ago,
            does_not_constitute_update: true,
          },
        ],
      }
      expect(response).to have_http_status :created

      expect(submission.reload.last_updated_at).to eq 3.days.ago
    end
  end
end
