require "rails_helper"

RSpec.describe Lograge do
  it "includes the request id for app log correlation" do
    headers = ActionDispatch::Http::Headers.from_hash(
      "HTTP_REQUEST_ID" => "nscc-submit-rails-request-id",
    )
    request = instance_double(ActionDispatch::Request, headers:)
    controller = instance_double(
      ApplicationController,
      current_client_role: :provider,
      request:,
    )

    expect(Rails.application.config.lograge.custom_payload_method.call(controller)).to eq(
      client_role: :provider,
      request_id: "nscc-submit-rails-request-id",
    )
  end
end
