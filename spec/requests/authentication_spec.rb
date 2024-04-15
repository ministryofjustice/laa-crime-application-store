require "rails_helper"

RSpec.describe "Authentication" do
  context "when no auth token is provided" do
    it "rejects all requests" do
      get "/v1/submissions"
      expect(response).to have_http_status :unauthorized
    end
  end

  context "when auth is not required" do
    around do |example|
      ENV["AUTHENTICATION_REQUIRED"] = "false"
      example.run
      ENV.delete("AUTHENTICATION_REQUIRED")
    end

    it "allows all requests" do
      get "/v1/submissions"
      expect(response).to have_http_status :ok
    end
  end

  context "when an auth token is provided" do
    around do |example|
      ENV["TENANT_ID"] = "TENANT"
      example.run
      ENV["TENANT_ID"] = nil
    end

    before do
      Tokens::VerificationService.instance_variable_set("@jwks", nil)
      stub_request(:get, "https://login.microsoftonline.com/TENANT/.well-known/openid-configuration")
        .to_return(status: 200,
                   body: { jwks_uri: "https://example.com/jwks" }.to_json,
                   headers: { "Content-type" => "application/json" })
      stub_request(:get, "https://example.com/jwks")
        .to_return(status: 200,
                   body: { keys: "keys" }.to_json,
                   headers: { "Content-type" => "application/json" })
    end

    context "when the token is invalid" do
      it "rejects the request" do
        get "/v1/submissions", headers: { "Authorization" => "Bearer ABC" }
        expect(response).to have_http_status :unauthorized
      end
    end

    context "when the token is valid" do
      let(:jwks) { instance_double(JWT::JWK::Set) }
      let(:decoded) do
        [{ "azp" => client_id,
           "aud" => "APP_STORE",
           "iss" => "https://login.microsoftonline.com/TENANT/v2.0",
           "exp" => 1.hour.from_now.to_i }]
      end

      around do |example|
        ENV["PROVIDER_CLIENT_ID"] = "PROVIDER"
        ENV["CASEWORKER_CLIENT_ID"] = "CASEWORKER"
        ENV["APP_CLIENT_ID"] = "APP_STORE"
        example.run
        ENV["PROVIDER_CLIENT_ID"] = nil
        ENV["CASEWORKER_CLIENT_ID"] = nil
        ENV["APP_CLIENT_ID"] = nil
      end

      before do
        allow(JWT::JWK::Set).to receive(:new).with("keys").and_return(jwks)
        allow(JWT).to receive(:decode).with("ABC", nil, true, { algorithms: "RS256", jwks: }).and_return(decoded)

        get "/v1/submissions", headers: { "Authorization" => "Bearer ABC" }
      end

      context "when caseworker client id is provided" do
        let(:client_id) { "CASEWORKER" }

        it "allows the request" do
          expect(response).to have_http_status :ok
        end
      end

      context "when provider client id is provided" do
        let(:client_id) { "PROVIDER" }

        it "allows the request" do
          expect(response).to have_http_status :ok
        end
      end

      context "when unknown client id is provided" do
        let(:client_id) { "UNKNOWN" }

        it "rejects the request" do
          expect(response).to have_http_status :unauthorized
        end
      end
    end
  end
end
