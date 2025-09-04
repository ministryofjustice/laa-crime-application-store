require "rails_helper"

RSpec.describe "list payment request", type: :request do
  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with payment requests" do
    before do
      create_list(:payment_request, 20,
                  payment_request_claim: build(:nsm_claim, client_last_name: "Andrex"))
    end

    it "successfully update when fields are valid" do
      get "/v1/payment_requests"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      payment_request_keys = %w[
        id
        payment_request_claim
        request_type
        submitted_at
        created_at
        updated_at
      ]

      get "/v1/payment_requests"
      expect(response.parsed_body["data"].first.keys.sort).to eq(payment_request_keys.sort)
    end

    it "returns expected payment_request_claim keys" do
      payable_keys = %w[
        laa_reference
        firm_name
        client_last_name
        claim_type
        office_code
      ]

      get "/v1/payment_requests"
      expect(response.parsed_body["data"].first["payment_request_claim"].keys.sort).to eq(payable_keys.sort)
    end
  end
end
