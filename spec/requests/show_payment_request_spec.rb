require "rails_helper"

RSpec.describe "show payment request", type: :request do
  let(:payment_id) { SecureRandom.uuid }
  let(:submitted_date) { Time.zone.local(2025, 1, 1) }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with payment request for NsmClaim" do
    before do
      create(
        :payment_request, :non_standard_mag, id: payment_id
      )
    end

    it "successfully update when fields are valid" do
      get "/v1/payment_requests/#{payment_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      payment_request_keys = %w[
        id
        allowed_disbursement_cost
        allowed_profit_cost
        allowed_travel_cost
        allowed_waiting_cost
        created_at
        date_claim_received
        disbursement_cost
        payment_request_claim
        profit_cost
        request_type
        submitted_at
        submitter_id
        travel_cost
        updated_at
        waiting_cost
      ]

      get "/v1/payment_requests/#{payment_id}"
      expect(response.parsed_body.keys.sort).to eq(payment_request_keys.sort)
    end

    it "returns expected payment_request_claim keys" do
      payable_keys = %w[
        claim_type
        laa_reference
        ufn
        date_received
        firm_name
        office_code
        stage_code
        client_first_name
        client_last_name
        work_completed_date
        outcome_code
        matter_type
        youth_court
        court_name
        court_attendances
        no_of_defendants
        created_at
        updated_at
      ]

      get "/v1/payment_requests/#{payment_id}"
      expect(response.parsed_body["payment_request_claim"].keys.sort).to eq(payable_keys.sort)
    end

    it "returns not found when not found" do
      get "/v1/payment_requests/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with payment request for AssignedCounselClaim" do
    before do
      create(
        :payment_request, :assigned_counsel, id: payment_id
      )
    end

    it "successfully update when fields are valid" do
      get "/v1/payment_requests/#{payment_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected payment request keys" do
      payment_request_keys = %w[
        id
        created_at
        date_claim_received
        payment_request_claim
        request_type
        submitted_at
        submitter_id
        net_assigned_counsel_cost
        assigned_counsel_vat
        allowed_net_assigned_counsel_cost
        allowed_assigned_counsel_vat
        updated_at
      ]

      get "/v1/payment_requests/#{payment_id}"

      expect(response.parsed_body.keys.sort).to eq(payment_request_keys.sort)
    end

    it "returns expected payable keys" do
      payable_keys = %w[
        claim_type
        laa_reference
        office_code
        nsm_claim_id
        date_received
        ufn
        solicitor_office_code
        client_last_name
        created_at
        updated_at
      ]
      get "/v1/payment_requests/#{payment_id}"
      expect(response.parsed_body["payment_request_claim"].keys.sort).to eq(payable_keys.sort)
    end

    it "returns not found when not found" do
      get "/v1/payment_requests/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
