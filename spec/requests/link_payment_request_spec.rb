require "rails_helper"

RSpec.describe "Link payment request" do
  let(:payment_id) { SecureRandom.uuid }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  context "when payment request is of type non_standard_mag" do
    let(:request_type) { "non_standard_mag" }

    before { create(:payment_request, id: payment_id, request_type: request_type, submitted_at: nil) }

    it "returns 422 when the request includes an laa_reference" do
      patch "/v1/payment_requests/#{payment_id}/link", params: {
        laa_reference: "LAA-abc123",
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns a successful response" do
      patch "/v1/payment_requests/#{payment_id}/link"

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id).payable_type).to eq("NsmClaim")
      expect(PaymentRequest.find(payment_id).payable.laa_reference).not_to be_nil
    end
  end
end
