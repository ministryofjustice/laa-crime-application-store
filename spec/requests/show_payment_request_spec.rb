require "rails_helper"

RSpec.describe "show payment request", type: :request do

  let(:payment_id) { SecureRandom.uuid }
  let(:submitted_date) { Time.zone.local(2025, 1, 1) }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with payment request for NsmClaim" do
    before do
      claim = create(:nsm_claim)
      create(
        :payment_request,
        :non_standard_mag,
        id: payment_id,
        payable: claim,
      )
    end

    it "successfully update when fields are valid" do
      get "/v1/payment_requests/#{payment_id}"
      debugger

      expect(response).to have_http_status(:success)
    end

    it "returns not found when not found" do
      get "/v1/payment_requests/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end
  context "with payment request for AssignedCounselClaim" do
    before do
      claim = create(:assigned_counsel_claim)
      create(
        :payment_request,
        :assigned_counsel,
        id: payment_id,
        payable: claim,
      )
    end

    it "successfully update when fields are valid" do
      get "/v1/payment_requests/#{payment_id}"
      debugger

      expect(response).to have_http_status(:success)
    end

    it "returns not found when not found" do
      get "/v1/payment_requests/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
