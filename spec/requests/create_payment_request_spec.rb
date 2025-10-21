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
      office_code: "3B123A",
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
        office_code: "3B123A",
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

    it "returns a 422 error" do
      post "/v1/payment_requests", params: {
        submitter_id:,
        request_type:,
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when laa_reference is supplied" do
    let(:laa_reference) { "LAA-abc123" }

    context "when request type is non_standard_mag" do
      let(:request_type) { "non_standard_mag" }

      context "when submission can't be linked" do
        before { allow(PaymentRequests::LinkPayableService).to receive(:call).and_raise(PaymentLinkError) }

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when submission can be linked" do
        before { allow(PaymentRequests::LinkPayableService).to receive(:call).and_return(true) }

        it "has a successful response" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:created)
        end
      end

      context "when no submission exists for the given laa reference" do
        before do
          create(:submission, :with_nsm_version, state: "granted", laa_reference: "LAA-xyz123")
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when the submission exists for the laa reference but it's the wrong type" do
        before do
          create(:submission, :with_pa_version, state: "granted", laa_reference: laa_reference)
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when a valid nsm submission exists for the laa reference" do
        let(:submission_id) { SecureRandom.uuid }
        let(:cost_totals) do
          {
            cost_summary: {
              profit_costs: {
                assessed_total_exc_vat: 637.04,
                assessed_total_inc_vat: 637.04,
                assessed_vat: 0.0,
                assessed_vatable: 0.0,
                claimed_total_exc_vat: 710.64,
                claimed_total_inc_vat: 710.64,
                claimed_vat: 0.0,
                claimed_vatable: 0.0,
              },
              disbursements: {
                claimed_total_exc_vat: 129.39,
                claimed_vatable: 123.85,
                claimed_vat: 24.77,
                claimed_total_inc_vat: 154.16,
                assessed_total_exc_vat: 128.34,
                assessed_vatable: 122.85,
                assessed_vat: 24.57,
                assessed_total_inc_vat: 152.91,
              },
              travel: {
                claimed_total_exc_vat: 0.0,
                assessed_total_exc_vat: 21.28,
                claimed_vatable: 0.0,
                claimed_vat: 0.0,
                claimed_total_inc_vat: 0.0,
                assessed_vatable: 0.0,
                assessed_vat: 0.0,
                assessed_total_inc_vat: 21.28,
              },
              waiting: {
                claimed_total_exc_vat: 67.3,
                assessed_total_exc_vat: 60.72,
                claimed_vatable: 0.0,
                claimed_vat: 0.0,
                claimed_total_inc_vat: 67.3,
                assessed_vatable: 0.0,
                assessed_vat: 0.0,
                assessed_total_inc_vat: 60.72,
              },
            },
          }
        end

        before do
          allow(LaaCrimeFormsCommon::Pricing::Nsm).to receive(:totals).and_return(cost_totals)
          create(:submission,
                 :with_nsm_version,
                 id: submission_id,
                 state: "granted",
                 account_number: "AAABBB",
                 laa_reference: laa_reference,
                 defendant_name: "Jim Jones")
        end

        it "succeeds and creates/links/autopopulates the correct records" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          built_submission = Submission.first
          built_payment = PaymentRequest.first
          built_claim = NsmClaim.first

          expect(response).to have_http_status(:created)

          expect(built_submission.latest_version.application["laa_reference"]).to eq(laa_reference)

          expect(built_claim.submission.id).to eq(submission_id)
          expect(built_claim).to have_attributes({
            solicitor_office_code: built_submission.latest_version.application["office_code"],
            laa_reference: built_submission.latest_version.application["laa_reference"],
            ufn: built_submission.latest_version.application["ufn"],
            stage_code: built_submission.latest_version.application["stage_reached"],
            client_first_name: "Jim",
            client_last_name: "Jones",
            work_completed_date: Time.zone.parse(built_submission.latest_version.application["work_completed_date"]),
            outcome_code: built_submission.latest_version.application["hearing_outcome"],
            matter_type: built_submission.latest_version.application["matter_type"],
            youth_court: built_submission.latest_version.application["youth_court"],
            court_name: built_submission.latest_version.application["court"],
            court_attendances: built_submission.latest_version.application["number_of_hearing"],
            no_of_defendants: built_submission.latest_version.application["defendants"].count,
          })

          expect(built_payment).to have_attributes({
            profit_cost: 710.64,
            travel_cost: 0.0,
            waiting_cost: 67.3,
            disbursement_cost: 154.16,
            allowed_profit_cost: 637.04,
            allowed_travel_cost: 21.28,
            allowed_waiting_cost: 60.72,
            allowed_disbursement_cost: 152.91,
          })
        end
      end

      context "when the submission that exists for the laa reference is prior authority" do
        before do
          create(:submission, :with_pa_version, laa_reference: laa_reference)
        end

        it "returns a 422 error" do
          post "/v1/payment_requests", params: {
            submitter_id:,
            request_type:,
            laa_reference:,
          }

          expect(response).to have_http_status(:unprocessable_entity)
        end
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
        solicitor_office_code: "3XYZ00A",
        date_claim_received: "2025-02-02",
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
      expect(claim.solicitor_office_code).to eq("3XYZ00A")

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
