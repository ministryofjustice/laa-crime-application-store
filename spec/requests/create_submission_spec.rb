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

    it "automatically adds a new version event" do
      id = SecureRandom.uuid
      post "/v1/submissions", params: {
        application_id: id,
        application_type: "crm4",
        application_state: "submitted",
        application_risk: "n/a",
        json_schema_version: 1,
        application: { foo: :bar },
      }
      expect(response).to have_http_status :created

      expect(created_record.reload.events.first).to include(
        "event_type" => "new_version",
      )
    end

    it "can autogrant" do
      stub_request(:get, "https://api.os.uk/search/names/v1/find?key=123&query=SW11AA").to_return(
        status: 200,
        body: {
          results: [
            {
              "GAZETTEER_ENTRY" => {
                "ID" => "SW11AA",
                "GEOMETRY_X" => 527_614.0,
                "GEOMETRY_Y" => 175_539.0,
              },
            },
          ],
        }.to_json,
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
      id = SecureRandom.uuid
      post "/v1/submissions",
           params: {
             application_id: id,
             application_type: "crm4",
             application_state: "submitted",
             application_risk: "n/a",
             json_schema_version: 1,
             application: {
               service_type: "ae_consultant",
               prison_law: false,
               rep_order_date: "2022-01-01",
               quotes: [
                 {
                   primary: true,
                   cost_type: :per_hour,
                   period: 60,
                   cost_per_hour: 10,
                   postcode: "SW1 1AA",
                 },
               ],
             },
           }.to_json,
           headers: { "Content-type": "application/json" }
      expect(response).to have_http_status :created

      expect(created_record.events.count).to eq 2
      expect(created_record.ordered_submission_versions.count).to eq 2
      expect(created_record.state).to eq "auto_grant"
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
