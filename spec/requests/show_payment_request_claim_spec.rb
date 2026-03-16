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
      get "/v1/payable_claims/#{nsm_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      keys = %w[
        assigned_counsel_claim
        defendant_first_name
        defendant_last_name
        court
        created_at
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

      get "/v1/payable_claims/#{nsm_id}"
      expect(response.parsed_body.keys.sort).to eq(keys.sort)
    end

    it "correctly formats the court field" do
      get "/v1/payment_request_claims/#{nsm_id}"
      expect(response.parsed_body["court"]).to eq("Leeds Court - 1")
    end

    context "when court is custom" do
      let(:custom_nsm_id) { SecureRandom.uuid }

      before do
        create(:nsm_claim, id: custom_nsm_id, court_id: "custom", court_name: "Custom Court")
      end

      it "correctly formats the court field for custom court" do
        get "/v1/payment_request_claims/#{custom_nsm_id}"
        expect(response.parsed_body["court"]).to eq("Custom Court - N/A")
      end
    end
  end

  context "with NsmClaim payment request claim attached to a submission" do
    let(:submission_id) { SecureRandom.uuid }

    before do
      @nsm_claim = create(:nsm_claim, id: nsm_id, submission_id: submission_id)
    end

    it "returns payload with linked submission id" do
      get "/v1/payable_claims/#{nsm_id}"
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
      get "/v1/payable_claims/#{assigned_counsel_id}"
      expect(response).to have_http_status(:success)
    end

    it "returns expected keys" do
      keys = %w[
        counsel_firm_name
        counsel_office_code
        created_at
        updated_at
        defendant_last_name
        id
        laa_reference
        nsm_claim
        payment_requests
        solicitor_firm_name
        solicitor_office_code
        type
        ufn
      ]

      get "/v1/payable_claims/#{assigned_counsel_id}"
      expect(response.parsed_body.keys.sort).to eq(keys.sort)
    end
  end

  it "returns not found when not found" do
    get "/v1/payable_claims/#{SecureRandom.uuid}"

    expect(response).to have_http_status(:not_found)
  end
end
