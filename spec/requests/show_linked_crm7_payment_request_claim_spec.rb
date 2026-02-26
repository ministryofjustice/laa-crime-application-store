require "rails_helper"

RSpec.describe "show payment request claim", type: :request do
  let(:nsm_id) { SecureRandom.uuid }

  before do
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with a CRM7 submission claim" do
    let(:submission) { create(:submission, :with_nsm_version) }
    let(:crm7_params) { { claim_type: "Crm7SubmissionClaim" } }

    it "successfully makes the request" do
      get "/v1/linked_claim/#{submission.id}", params: crm7_params
      expect(response).to have_http_status(:success)
    end

    it "returns similar keys to the payment request claim resource" do
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

      get "/v1/payment_request_claims/#{submission.id}", params: crm7_params
      expect(response.parsed_body.keys.sort).to eq(keys.sort)
    end

    it "returns CRM7 specific values" do
      get "/v1/payment_request_claims/#{submission.id}", params: crm7_params

      expect(response.parsed_body).to include(
        "id" => submission.id,
        "submission_id" => submission.id,
        "type" => "Crm7SubmissionClaim",
        "laa_reference" => submission.ordered_submission_versions.first.application["laa_reference"],
      )
    end
  end


  it "returns not found when not found" do
    get "/v1/linked_claim/#{SecureRandom.uuid}"

    expect(response).to have_http_status(:not_found)
  end
end
