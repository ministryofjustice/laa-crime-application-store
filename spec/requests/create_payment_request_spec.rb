require "rails_helper"

RSpec.describe "Create payment request" do
  let(:submitted_date) { Time.zone.local(2025, 1, 1) }
  let(:submitter_id) { SecureRandom.uuid }
  let(:request_type) { "non_standard_mag" }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  it "can create payment request with valid params" do
    post "/v1/payment_requests", params: {
      submitter_id:,
      request_type:,
    }

    expect(response).to have_http_status(:created)
  end

  context "when submitter_id is invalid" do
    let(:submitter_id) { "garbage" }

    it "returns a 422 error" do
      post "/v1/payment_requests", params: {
        submitter_id:,
        request_type:,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when request_type is invalid" do
    let(:request_type) { "garbage" }

    it "returns a 422 error" do
      post "/v1/payment_requests", params: {
        submitter_id:,
        request_type:,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
