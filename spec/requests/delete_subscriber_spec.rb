require "rails_helper"

RSpec.describe "DELETE /v1/subscribers" do
  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role:) }

  let(:role) { :provider }

  it "deletes a record" do
    subscriber = create :subscriber, subscriber_type: "provider"
    delete "/v1/subscribers", params: { webhook_url: subscriber.webhook_url, subscriber_type: subscriber.subscriber_type }
    expect(response).to have_http_status(:no_content)
    expect(Subscriber.count).to eq 0
  end

  it "handles missing records" do
    delete "/v1/subscribers", params: { webhook_url: "a", subscriber_type: "provider" }
    expect(response).to have_http_status(:not_found)
  end

  context "when I have a different role to the one I am trying to delete" do
    let(:role) { :caseworker }

    it "prevents me from deleting subscribers not my own" do
      subscriber = create :subscriber, subscriber_type: "provider"
      delete "/v1/subscribers", params: { webhook_url: subscriber.webhook_url, subscriber_type: subscriber.subscriber_type }
      expect(response).to have_http_status(:forbidden)
    end
  end
end
