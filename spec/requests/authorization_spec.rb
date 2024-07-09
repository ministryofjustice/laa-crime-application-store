require "rails_helper"

RSpec.describe "Authorization" do
  context "when authentication is not being done" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV.delete("AUTHENTICATION_REQUIRED")
    end

    it "allows requests based on the X-Client-Type" do
      get "/v1/submissions", headers: { "X-Client-Type" => "provider" }
      expect(response).to have_http_status :ok
    end

    it "denies requests without the X-Client-Type" do
      get "/v1/submissions"
      expect(response).to have_http_status :forbidden
    end

    it "denies requests if the client type cannot do the thing they want to do" do
      post "/v1/submissions", headers: { "X-Client-Type" => "caseworker" }
      # caseworkers cannot create submissions
      expect(response).to have_http_status :forbidden
    end

    it "denies requests if the object is not in a state that permits modifications" do
      submission = create(:submission, application_state: "granted")
      # providers can only modify submissions that are in the 'sent_back' state
      patch "/v1/submissions/#{submission.id}", headers: { "X-Client-Type" => "provider" }
      expect(response).to have_http_status :forbidden
    end

    it "denies requests if the specific change requested is forbidden" do
      submission = create(:submission, application_state: "submitted")
      # caseworkers cannot mark submissions as provider_updated
      patch "/v1/submissions/#{submission.id}",
            params: { application_state: "provider_updated" },
            headers: { "X-Client-Type" => "caseworker" }
      expect(response).to have_http_status :forbidden
    end
  end

  context "when a valid auth token is provided" do
    let(:decoded) { [{ "roles" => [role] }] }

    before do
      allow(Tokens::VerificationService).to receive_messages(parse: decoded, valid?: true)
    end

    context "when client is doing something it is allowed to based on its token" do
      let(:role) { "Caseworker" }

      it "allows them to do it" do
        submission = create(:submission, application_state: "submitted")
        patch "/v1/submissions/#{submission.id}",
              headers: { "Authorization" => "Bearer ABC" },
              params: { application_state: "granted", application: { new: :data }, json_schema_version: 1 }
        expect(response).to have_http_status :created
      end
    end

    context "when client is doing something it is not allowed to based on its token" do
      let(:role) { "Provider" }

      it "does not allow them to do it" do
        submission = create(:submission, application_state: "submitted")
        patch "/v1/submissions/#{submission.id}",
              headers: { "Authorization" => "Bearer ABC" },
              params: { application_state: "granted" }
        expect(response).to have_http_status :forbidden
      end
    end

    context "when client is making a change that would have no impact" do
      let(:role) { "Caseworker" }
      let(:params) { { events: [{ id: "ABC" }] } }
      let(:submission) { create(:submission, application_state: state, events: [{ id: "ABC" }]) }

      before do
        post "/v1/submissions/#{submission.id}/events",
             headers: { "Authorization" => "Bearer ABC" },
             params:
      end

      context "when the type of operation would be forbidden" do
        let(:state) { "granted" }

        it "returns a 204 status" do
          expect(response).to have_http_status :no_content
        end
      end

      context "when the type of operation would be allowed" do
        let(:state) { "submitted" }

        it "still returns a 204 status" do
          expect(response).to have_http_status :no_content
        end
      end
    end
  end
end
