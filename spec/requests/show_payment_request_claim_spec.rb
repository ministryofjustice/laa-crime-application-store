require "rails_helper"

RSpec.describe "show payment request claim", type: :request do
  let(:nsm_id) { SecureRandom.uuid }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with payment request claim for NsmClaim" do
    before do
      create(:nsm_claim, id: nsm_id)
    end

    it "successfully makes the request" do
      get "/v1/payment_request_claims/#{nsm_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      keys = %w[
        id
        type
        laa_reference
        date_received
        solicitor_office_code
        solicitor_firm_name
        stage_code
        work_completed_date
        court_name
        court_attendances
        no_of_defendants
        client_first_name
        client_last_name
        outcome_code
        matter_type
        youth_court
        ufn
        submission_id
        created_at
        updated_at
        payment_requests
        assigned_counsel_claim
      ]

      get "/v1/payment_request_claims/#{nsm_id}"
      expect(response.parsed_body.keys.sort).to eq(keys.sort)
    end
  end

  context "with NsmClaim payment request claim attached to a submission" do
    let(:submission_id) { SecureRandom.uuid }

    before do
      submission = create(:submission, :with_nsm_version, id: submission_id)
      create(:nsm_claim, id: nsm_id, submission: submission)
    end

    it "returns payload with linked submission id" do
      get "/v1/payment_request_claims/#{nsm_id}"
      expect(response.parsed_body["submission_id"]).to eq(submission_id)
    end
  end

  context "with payment request claim for AssignedCounselClaim" do
    let(:assigned_counsel_id) { SecureRandom.uuid }
    let(:claim) { create(:nsm_claim) }

    before do
      create(:assigned_counsel_claim, id: assigned_counsel_id, nsm_claim: claim)
    end

    it "successfully makes the request" do
      get "/v1/payment_request_claims/#{assigned_counsel_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      keys = %w[
        id
        type
        laa_reference
        date_received
        counsel_office_code
        counsel_firm_name
        solicitor_office_code
        solicitor_firm_name
        client_last_name
        submission_id
        created_at
        updated_at
        payment_requests
        nsm_claim
      ]

      get "/v1/payment_request_claims/#{assigned_counsel_id}"
      expect(response.parsed_body.keys.sort).to eq(keys.sort)
    end
  end

  it "returns not found when not found" do
    get "/v1/payment_request_claims/#{SecureRandom.uuid}"

    expect(response).to have_http_status(:not_found)
  end
end
