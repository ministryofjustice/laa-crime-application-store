require "rails_helper"

RSpec.describe "POST /v1/payment_requests", type: :request do
  subject(:make_request) { post(endpoint, params:) }

  let(:endpoint) { "/v1/payment_requests" }
  let(:submitter_id) { SecureRandom.uuid }
  let(:request_type) { "non_standard_mag" }
  let(:laa_reference) { nil }
  let(:params) do
    {
      submitter_id:,
      request_type:,
      laa_reference:,
      date_received: "2025-01-01",
      solicitor_office_code: "3B123A",
      solicitor_firm_name: "The Firm",
      defendant_first_name: "Jim",
      defendant_last_name: "Jones",
      matter_type: "CRIM",
      hearing_outcome_code: "PROG",
      stage_reached: "PROG",
      ufn: "010125/001",
      youth_court: false,
      number_of_attendances: 2,
      number_of_defendants: 1,
      date_completed: "2025-01-01",
      court: "Greenock Sheriff",
      claimed_profit_costs: 100.0,
      claimed_travel_costs: 20.0,
      claimed_waiting_costs: 10.0,
      claimed_disbursement_costs: 5.0,
      allowed_profit_costs: 90.0,
      allowed_travel_costs: 15.0,
      allowed_waiting_costs: 5.0,
      allowed_disbursement_costs: 4.0,
    }
  end

  before do
    allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("test")
    allow(Sentry).to receive(:capture_exception)
    allow(Tokens::VerificationService)
      .to receive(:call)
      .and_return(valid: true, role: :caseworker)
  end

  describe "successful creation" do
    it "creates an NSM claim and linked payment request" do
      expect { make_request }.to change(PaymentRequest, :count).by(1)
                             .and change(NsmClaim, :count).by(1)

      expect(response).to have_http_status(:created)

      payment = PaymentRequest.last
      claim = NsmClaim.last

      expect(payment.request_type).to eq("non_standard_mag")
      expect(payment.submitter_id).to eq(submitter_id)
      expect(payment.payment_request_claim).to eq(claim)

      expect(claim).to have_attributes(
        client_first_name: "Jim",
        client_last_name: "Jones",
        solicitor_office_code: "3B123A",
        solicitor_firm_name: "The Firm",
        matter_type: "CRIM",
        youth_court: false,
        court_name: "Greenock Sheriff",
        stage_code: "PROG",
        no_of_defendants: 1,
      )

      expect(payment).to have_attributes(
        profit_cost: 100.0,
        travel_cost: 20.0,
        waiting_cost: 10.0,
        disbursement_cost: 5.0,
        allowed_profit_cost: 90.0,
        allowed_travel_cost: 15.0,
        allowed_waiting_cost: 5.0,
        allowed_disbursement_cost: 4.0,
      )
    end
  end

  describe "validation errors" do
    context "when submitter_id is invalid" do
      let(:submitter_id) { "not-a-uuid" }

      it "returns 422 and no records created" do
        expect { make_request }.not_to change(PaymentRequest, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when request_type is invalid" do
      let(:request_type) { "invalid_type" }

      it "returns 422" do
        make_request
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when required attributes are missing" do
      let(:params) { super().except(:office_code, :ufn) }

      it "returns 422 and does not create claim" do
        expect { make_request }.not_to change(NsmClaim, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "when creating an assigned counsel claim" do
    let(:request_type) { "assigned_counsel" }
    let(:params) do
      {
        submitter_id:,
        request_type:,
        nsm_claim_id: create(:nsm_claim).id,
        laa_reference:,
        counsel_office_code: "2C123B",
        counsel_firm_name: "Counsel Firm",
        solicitor_office_code: "3B123A",
        solicitor_firm_name: "Solicitor Firm",
        date_received: "2025-02-02",
        net_assigned_counsel_cost: 500.0,
        assigned_counsel_vat: 100.0,
        allowed_net_assigned_counsel_cost: 450.0,
        allowed_assigned_counsel_vat: 90.0,
      }
    end

    it "creates an AssignedCounselClaim and linked PaymentRequest" do
      expect { make_request }.to change(AssignedCounselClaim, :count).by(1)
                             .and change(PaymentRequest, :count).by(1)

      expect(response).to have_http_status(:created)

      payment = PaymentRequest.last
      claim = AssignedCounselClaim.last

      expect(payment.request_type).to eq("assigned_counsel")
      expect(payment.payment_request_claim).to eq(claim)
      expect(claim.counsel_office_code).to eq("2C123B")
      expect(claim.solicitor_office_code).to eq("3B123A")

      expect(payment).to have_attributes(
        net_assigned_counsel_cost: 500.0,
        assigned_counsel_vat: 100.0,
        allowed_net_assigned_counsel_cost: 450.0,
        allowed_assigned_counsel_vat: 90.0,
      )
    end

    describe "SENTRY error reporting" do
      let(:submitter_id) { "not-a-uuid" }

      it "logs a Sentry exception" do
        make_request

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Sentry).to have_received(:capture_exception)
      end
    end
  end
end
