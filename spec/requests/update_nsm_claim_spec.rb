require "rails_helper"

RSpec.describe "Update nsm_claim" do
  let(:nsm_claim_id) { SecureRandom.uuid }
  let(:date) { Time.zone.local(2025, 1, 1) }

  before do
    allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("test")
    allow(Sentry).to receive(:capture_exception)
    allow(Tokens::VerificationService).to receive(:call).and_return(valid: true, role: :caseworker)
  end

  context "with NsmClaim" do
    before do
      create(:nsm_claim, id: nsm_claim_id )
    end

    it "successfully update when fields are valid" do
      patch "/v1/nsm_claims/#{nsm_claim_id}", params: {
        ufn: "120423/002",
        date_received: date,
        firm_name: "Fred Inc",
        office_code: "123BBB",
        stage_code: "PROG",
        client_last_name: "Jones",
        work_completed_date: date,
        court_name: "Some Court",
        court_attendances: 5,
        no_of_defendants: 1,
      }

      expect(response).to have_http_status(:created)
      expect(NsmClaim.find(nsm_claim_id)).to have_attributes(
        ufn: "120423/002",
        date_received: date,
        firm_name: "Fred Inc",
        office_code: "123BBB",
        stage_code: "PROG",
        client_last_name: "Jones",
        work_completed_date: date,
        court_name: "Some Court",
        court_attendances: 5,
        no_of_defendants: 1,
      )
    end

    it "returns not found when trying to update non existing record" do
      patch "/v1/nsm_claims/#{SecureRandom.uuid}"

      expect(response).to have_http_status(:not_found)
    end

    it "fails to update when fields are invalid" do
      patch "/v1/nsm_claims/#{nsm_claim_id}", params: {
        office_code: "X123BBB",
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Sentry).to have_received(:capture_exception)
    end
  end
end
