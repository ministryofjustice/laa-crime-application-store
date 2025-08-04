require "rails_helper"

RSpec.describe "Update assigned counsel claim" do
  let(:params) do
    {
      counsel_office_code: "12ABC",
      ufn: "12122024/001",
      solicitor_office_code: "89XYZ",
      client_last_name: "Smith",
      date_received: Time.zone.local(2025, 1, 1),
    }
  end
  let(:assigned_counsel_claim) { create(:assigned_counsel_claim) }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  context "with AssignedCounselClaim" do
    it "successfully update when fields are valid" do
      patch "/v1/assigned_counsel_claims/#{assigned_counsel_claim.id}", params: params

      expect(response).to have_http_status(:created)
      expect(AssignedCounselClaim.find(assigned_counsel_claim.id)).to have_attributes(params)
    end

    it "returns not found when trying to update non existing record" do
      patch "/v1/assigned_counsel_claims/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "fails to update when allowed fields have invalid data" do
      patch "/v1/assigned_counsel_claims/#{assigned_counsel_claim.id}", params: {
        counsel_office_code: "ABC123!"
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
