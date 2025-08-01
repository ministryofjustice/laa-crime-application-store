require "rails_helper"

RSpec.describe "Update payment request" do
  let(:payment_id) { SecureRandom.uuid }
  let(:submitted_date) { Time.zone.local(2025, 1, 1) }

  before do
    allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("test")
    allow(Sentry).to receive(:capture_exception)
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
      patch "/v1/payment_requests/#{payment_id}", params: {
        profit_cost: 101,
        travel_cost: 44.55,
        waiting_cost: 11.20,
        disbursement_cost: 70.44,
        allowed_profit_cost: 80,
        allowed_travel_cost: 33.22,
        allowed_waiting_cost: 10,
        allowed_disbursement_cost: 55,
        submitted_at: submitted_date,
      }

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id)).to have_attributes(
        profit_cost: 101.00,
        travel_cost: 44.55,
        waiting_cost: 11.20,
        disbursement_cost: 70.44,
        allowed_profit_cost: 80.00,
        allowed_travel_cost: 33.22,
        allowed_waiting_cost: 10.00,
        allowed_disbursement_cost: 55.00,
        submitted_at: submitted_date,
      )
    end

    it "returns not found when trying to update non existing record" do
      patch "/v1/payment_requests/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "fails to update when fields are invalid" do
      patch "/v1/payment_requests/#{payment_id}", params: {
        profit_cost: "ABC",
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Sentry).to have_received(:capture_exception)
    end

    it "fails to update when costs are negative" do
      patch "/v1/payment_requests/#{payment_id}", params: {
        profit_cost: -50,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "ignores updating assigned counsel related costs" do
      patch "/v1/payment_requests/#{payment_id}", params: {
        profit_cost: 101,
        net_assigned_counsel_cost: 200,
        assigned_counsel_vat: 40,
        allowed_net_assigned_counsel_cost: 100,
        allowed_assigned_counsel_vat: 20,
      }

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id)).to have_attributes(
        profit_cost: 101.00,
        net_assigned_counsel_cost: nil,
        assigned_counsel_vat: nil,
        allowed_net_assigned_counsel_cost: nil,
        allowed_assigned_counsel_vat: nil,
      )
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
      patch "/v1/payment_requests/#{payment_id}", params: {
        net_assigned_counsel_cost: 200,
        assigned_counsel_vat: 40,
        submitted_at: submitted_date,
      }

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id)).to have_attributes(
        net_assigned_counsel_cost: 200.00,
        assigned_counsel_vat: 40.00,
        submitted_at: submitted_date,
      )
    end

    it "ignores updating non-standard mag related costs" do
      patch "/v1/payment_requests/#{payment_id}", params: {
        profit_cost: 101,
        net_assigned_counsel_cost: 200,
        assigned_counsel_vat: 40,
        allowed_net_assigned_counsel_cost: 100,
        allowed_assigned_counsel_vat: 20,
      }

      expect(response).to have_http_status(:created)
      expect(PaymentRequest.find(payment_id)).to have_attributes(
        profit_cost: nil,
        net_assigned_counsel_cost: 200.00,
        assigned_counsel_vat: 40.00,
        allowed_net_assigned_counsel_cost: 100.00,
        allowed_assigned_counsel_vat: 20.00,
      )
    end
  end
end
