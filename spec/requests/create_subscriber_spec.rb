require "rails_helper"

RSpec.describe "POST /v1/subscribers" do
  it "creates a record" do
    post "/v1/subscribers", params: { webhook_url: "a", subscriber_type: "b" }
    expect(response).to have_http_status(:created)
    expect(Subscriber.find_by(webhook_url: "a", subscriber_type: "b")).not_to be_nil
  end

  it "handles duplicates" do
    subscriber = create :subscriber
    post "/v1/subscribers", params: { webhook_url: subscriber.webhook_url, subscriber_type: subscriber.subscriber_type }
    expect(response).to have_http_status(:no_content)
    expect(Subscriber.count).to eq 1
  end

  it "handles validation" do
    post "/v1/subscribers", params: { webhook_url: nil, subscriber_type: "b" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Subscriber.count).to eq 0
  end
end
