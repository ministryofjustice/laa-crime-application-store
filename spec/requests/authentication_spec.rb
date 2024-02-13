require "rails_helper"

RSpec.describe "Authentication" do
  context "when no auth token is provided" do
    it "rejects all requests" do
      get "/v1/submissions"
      expect(response).to have_http_status :unauthorized
    end
  end

  context "when an auth token is provided" do
    before do
      AuthenticationService.instance_variable_set("@jwks", nil)
      stub_request(:get, "https://login.microsoftonline.com/UNDEFINED_APP_STORE_TENANT_ID/.well-known/openid-configuration")
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
        [{ "aud" => "UNDEFINED_APP_STORE_CLIENT_ID",
           "iss" => "https://login.microsoftonline.com/UNDEFINED_APP_STORE_TENANT_ID/v2.0",
           "exp" => 1.hour.from_now.to_i }]
      end

      before do
        allow(JWT::JWK::Set).to receive(:new).with("keys").and_return(jwks)
        allow(JWT).to receive(:decode).with("ABC", nil, true, { algorithms: "RS256", jwks: }).and_return(decoded)
      end

      it "allows the request" do
        get "/v1/submissions", headers: { "Authorization" => "Bearer ABC" }
        expect(response).to have_http_status :ok
      end
    end
  end
end
