require "que"
require "httparty"
require "./notify_subscriber_job"

RSpec.describe NotifySubscriberJob do
  describe "#run" do
    let(:provider) { instance_double(TokenProvider) }
    let(:response) { double(:response, code:) }
    let(:endpoint) { "https://www.example.com/webhook" }
    let(:submission_id) { "123" }

    before do
      allow(TokenProvider).to receive(:instance).and_return(provider)
    end

    context "when authentication is not configured" do
      before do
        allow(provider).to receive(:authentication_configured?).and_return(false)
        allow(HTTParty).to receive(:post).and_return(response)
      end

      context "when request is successful" do
        let(:code) { 200 }

        it "pings the endpoint" do
          described_class.run(endpoint, submission_id)
          expect(HTTParty).to have_received(:post).with(
            endpoint, headers: {}, body: { submission_id: }
          )
        end
      end

      context "when request fails" do
        let(:code) { 500 }

        it "raises an exception" do
          expect { described_class.run(endpoint, submission_id) }.to raise_error(
            "Unexpected response from subscriber - status 500",
          )
        end
      end
    end

    context "when authentication is configured" do
      before do
        allow(provider).to receive(:authentication_configured?).and_return(true)
        allow(provider).to receive(:bearer_token).and_return(bearer_token)
        allow(HTTParty).to receive(:post).and_return(response)
      end

      let(:code) { 200 }
      let(:bearer_token) { "ABC" }

      it "pings the endpoint with " do
        described_class.run(endpoint, submission_id)
        expect(HTTParty).to have_received(:post).with(
          endpoint, headers: { authorization: "Bearer #{bearer_token}" }, body: { submission_id: }
        )
      end
    end
  end
end
