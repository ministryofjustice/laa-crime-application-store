# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssignedCounselClaim, type: :model do
  describe "validations" do
    let(:nsm_claim) { create(:nsm_claim) }

    it "is valid with all required attributes" do
      claim = build(:assigned_counsel_claim, nsm_claim: nsm_claim)
      expect(claim).to be_valid
    end

    it "is invalid without nsm_claim_id" do
      claim = build(:assigned_counsel_claim, nsm_claim: nil)
      expect(claim).not_to be_valid
      expect(claim.errors[:nsm_claim_id]).to include("can't be blank")
    end

    it "is invalid without solicitor_office_code" do
      claim = build(:assigned_counsel_claim, nsm_claim: nsm_claim, solicitor_office_code: nil)
      expect(claim).not_to be_valid
      expect(claim.errors[:solicitor_office_code]).to include("Must be an alphanumeric string starting with a number and ending in a letter")
    end

    it "invalidates record when counsel_office_code isnt alphanumeric starting with number and ending in letter" do
      claim = build(:assigned_counsel_claim, nsm_claim: nsm_claim, solicitor_office_code: "ABCD1234")
      expect(claim).not_to be_valid
      expect(claim.errors[:solicitor_office_code]).to include("Must be an alphanumeric string starting with a number and ending in a letter")
    end
  end

  describe "inheritance" do
    it "inherits from PaymentRequestClaim" do
      expect(described_class < PaymentRequestClaim).to be(true)
    end
  end

  describe "factory" do
    it "creates a valid record" do
      nsm_claim = create(:nsm_claim)
      claim = create(:assigned_counsel_claim, nsm_claim: nsm_claim)

      expect(claim).to be_persisted
      expect(claim.nsm_claim).to eq(nsm_claim)
    end
  end
end
