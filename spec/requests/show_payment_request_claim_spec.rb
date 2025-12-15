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
        assigned_counsel_claim
        court
        created_at
        defendant_first_name
        defendant_last_name
        hearing_outcome_code
        id
        laa_reference
        matter_type
        number_of_attendances
        number_of_defendants
        payment_requests
        solicitor_firm_name
        solicitor_office_code
        stage_reached
        submission_id
        type
        ufn
        updated_at
        work_completed_date
        youth_court
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
        counsel_firm_name
        counsel_office_code
        court
        created_at
        defendant_first_name
        defendant_last_name
        hearing_outcome_code
        id
        laa_reference
        nsm_claim
        number_of_attendances
        number_of_defendants
        payment_requests
        solicitor_firm_name
        solicitor_office_code
        stage_reached
        submission_id
        type
        updated_at
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
