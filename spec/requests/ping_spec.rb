require "rails_helper"

RSpec.describe "Ping" do
  it "has an OK status code" do
    get "/ping"
    expect(response).to have_http_status :ok
  end
end
