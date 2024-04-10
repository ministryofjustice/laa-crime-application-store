# frozen_string_literal: true

require "./token_provider"
require "webmock/rspec"

RSpec.shared_context "with nil access token" do
  let(:previous_access_token) { client.instance_variable_get(:@access_token) }

  before do
    # remove @access_token to ensure a new oauth token request is made, otherwise previous
    # calls in tests could mean the token exists already and has not expired, causing
    # the oauth/token endpoint to not be hit, resulting in test failure or flickers if oauth/token
    # end point hitting is expected by the test :(
    previous_access_token
    client.instance_variable_set(:@access_token, nil)
  end

  after do
    client.instance_variable_set(:@access_token, previous_access_token)
  end
end

RSpec.describe TokenProvider do
  subject(:client) { described_class.instance }

  before do
    stub_request(:post, %r{https.*/oauth2/v2.0/token})
      .to_return(
        status: 200,
        body: '{"access_token":"test-bearer-token","token_type":"Bearer","expires_in":3600,"created_at":1582809000}',
        headers: { "Content-Type" => "application/json; charset=utf-8" },
      )
  end

  it { is_expected.to respond_to :oauth_client, :access_token, :bearer_token }

  describe "#oauth_client", :stub_oauth_token do
    subject { described_class.instance.oauth_client }

    it { is_expected.to be_an OAuth2::Client }
    it { is_expected.to respond_to :client_credentials }
  end

  describe "#access_token", :stub_oauth_token do
    subject(:access_token) { client.access_token }

    it { is_expected.to be_an OAuth2::AccessToken }
    it { is_expected.to respond_to :token }
    it { expect(access_token.token).to eql "test-bearer-token" }

    context "when token nil?" do
      include_context "with nil access token"

      it "retrieves new access_token" do
        allow(client).to receive(:new_access_token)
        access_token
        expect(client).to have_received(:new_access_token)
      end
    end
  end

  describe "#bearer_token", :stub_oauth_token do
    subject(:bearer_token) { client.bearer_token }

    it { is_expected.to be_a String }
    it { is_expected.to eql "test-bearer-token" }
  end

  describe "#authentication_configured?" do
    subject(:authentication_configured) { client.authentication_configured? }

    around do |spec|
      normal_tenant_id = ENV.fetch("APP_STORE_TENANT_ID", nil)

      ENV["APP_STORE_TENANT_ID"] = tenant_id
      spec.run
      ENV["APP_STORE_TENANT_ID"] = normal_tenant_id
    end

    context "when there is a tenant_id" do
      let(:tenant_id) { "123" }

      it { is_expected.to be true }
    end

    context "when there is no tenant_id" do
      let(:tenant_id) { nil }

      it { is_expected.to be false }
    end
  end
end
