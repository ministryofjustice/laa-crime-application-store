require "rails_helper"

RSpec.describe "Create submission" do
  context "when authenticated with bearer token" do
    before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :provider) }

    let(:created_record) { Submission.last }

    it "saves what I send" do
      id = SecureRandom.uuid
      post "/v1/submissions", params: {
        application_id: id,
        application_type: "crm4",
        application_state: "submitted",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }
      expect(response).to have_http_status :created

      expect(created_record).to have_attributes(
        id:,
        state: "submitted",
        application_type: "crm4",
        application_risk: "low",
        current_version: 1,
        last_updated_at: created_record.created_at,
      )

      expect(created_record.latest_version).to have_attributes(
        json_schema_version: 1,
        application: { "foo" => "bar" },
      )
    end

    it "updates last_updated_at from params" do
      freeze_time do
        id = SecureRandom.uuid
        updated_at_time = 1.hour.ago

        post "/v1/submissions", params: {
          application_id: id,
          application_type: "crm4",
          application_state: "submitted",
          application_risk: "low",
          json_schema_version: 1,
          application: {
            foo: :bar,
            "created_at" => (updated_at_time - 15.minutes).iso8601,
            "updated_at" => updated_at_time.iso8601,
          },
        }

        expect(created_record).to have_attributes(
          id:,
          state: "submitted",
          application_type: "crm4",
          application_risk: "low",
          current_version: 1,
          last_updated_at: updated_at_time,
        )

        expect(created_record.latest_version)
          .to have_attributes(
            json_schema_version: 1,
            application: {
              "foo" => "bar",
              "created_at" => (updated_at_time - 15.minutes).iso8601,
              "updated_at" => updated_at_time.iso8601,
            },
          )
      end
    end

    it "validates what I send" do
      post "/v1/submissions", params: {
        application_id: SecureRandom.uuid,
        application_state: "submitted",
      }
      expect(response).to have_http_status :unprocessable_entity
    end

    it "detects a forbidden state" do
      post "/v1/submissions", params: {
        application_id: SecureRandom.uuid,
        application_state: "granted",
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect(response).to have_http_status :forbidden
    end

    it "detects conflicting information" do
      submission = create(:submission)
      post "/v1/submissions", params: {
        application_id: submission.id,
        application_state: "submitted",
      }
      expect(response).to have_http_status :conflict
    end

    it "enqueues a job to notify a subscriber with a different role" do
      create(:subscriber, subscriber_type: "caseworker")
      params = {
        application_id: SecureRandom.uuid,
        application_state: "submitted",
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect { post("/v1/submissions", params:) }.to have_enqueued_job
    end

    it "ignores subscribers with same roles as client" do
      create(:subscriber, subscriber_type: "provider")
      params = {
        application_id: SecureRandom.uuid,
        application_state: "submitted",
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect { post("/v1/submissions", params:) }.not_to have_enqueued_job
    end
  end

  context "when not using token" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV["AUTHENTICATION_REQUIRED"] = nil
    end

    it "enqueues a job to notify a subscriber with a different role" do
      create(:subscriber, subscriber_type: "caseworker")
      params = {
        application_id: SecureRandom.uuid,
        application_state: "submitted",
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect { post("/v1/submissions", params:, headers: { "X-Client-Type": "provider" }) }.to have_enqueued_job
    end

    it "ignores subscribers with same roles as client" do
      create(:subscriber, subscriber_type: "provider")
      params = {
        application_id: SecureRandom.uuid,
        application_state: "submitted",
        application_type: "crm4",
        application_risk: "low",
        json_schema_version: 1,
        application: { foo: :bar },
      }

      expect { post("/v1/submissions", params:, headers: { "X-Client-Type": "provider" }) }.not_to have_enqueued_job
    end
  end
end
