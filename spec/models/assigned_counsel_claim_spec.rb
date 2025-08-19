require "rails_helper"

RSpec.describe AssignedCounselClaim do
  describe "#counsel_office_code" do
    let(:claim) { create(:nsm_claim) }
    let(:assigned_counsel_claim) { create(:assigned_counsel_claim, nsm_claim: claim) }

    it "invalidates record when counsel_office_code isnt alphanumeric starting with number and ending in letter" do
      assigned_counsel_claim.office_code = "ABCD1234"
      assigned_counsel_claim.validate
      expect(assigned_counsel_claim.valid?).to be(false)
    end

    it "validates record when counsel_office_code is alphanumeric starting with number and ending in letter" do
      assigned_counsel_claim.office_code = "1234ABCD"
      assigned_counsel_claim.validate
      expect(assigned_counsel_claim.valid?).to be(true)
    end
  end
end
