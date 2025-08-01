require "rails_helper"

RSpec.describe "Update assigned counsel claim" do
  let(:counsel_office_code) { "12ZXXaX" }
  let(:nsm_claim) { create(:nsm_claim) }
  let(:assigned_counsel_claim) { create(:assigned_counsel_claim, nsm_claim:) }

  before { allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker) }

  context "with AssignedCounselClaim" do
    it "successfully update when fields are valid" do
      patch "/v1/assigned_counsel_claims/#{assigned_counsel_claim.id}", params: {
        assigned_counsel_claim: { counsel_office_code: counsel_office_code },
      }

      expect(response).to have_http_status(:created)
      expect(AssignedCounselClaim.find(assigned_counsel_claim.id)).to have_attributes(
        counsel_office_code:,
      )
    end

    it "returns not found when trying to update non existing record" do
      patch "/v1/assigned_counsel_claims/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "fails to update when fields are invalid" do
      patch "/v1/assigned_counsel_claims/#{assigned_counsel_claim.id}", params: {
        profit_cost: "ABC",
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "fails to update when allowed fields have invalid data" do
      patch "/v1/assigned_counsel_claims/#{assigned_counsel_claim.id}", params: {
        assigned_counsel_claim: { counsel_office_code: "ABC123!" },
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
