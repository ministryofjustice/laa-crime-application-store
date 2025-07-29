require "rails_helper"

RSpec.describe LaaReferenceHelper, type: :helper do
  describe "#reference_already_exists?" do
    before do
      create(:nsm_claim, laa_reference: "LAA-abc123")
      create(:assigned_counsel_claim, laa_reference: "LAA-xyz321")
      create(:submission, laa_reference: "LAA-yfg343")
    end

    it "returns false if the reference does not exist" do
      expect(helper.reference_already_exists?("LAA-bvr321")).to be false
    end

    it "returns true when the reference is for a Submission" do
      expect(helper.reference_already_exists?("LAA-yfg343")).to be true
    end

    it "returns true when the reference is for a AssignedCounselClaim" do
      expect(helper.reference_already_exists?("LAA-xyz321")).to be true
    end

    it "returns true when the reference is for a NsmClaim" do
      expect(helper.reference_already_exists?("LAA-abc123")).to be true
    end
  end

  describe "#find_referred_submission" do
    let(:submission_id) { SecureRandom.uuid }

    before do
      create(:submission, id: submission_id, laa_reference: "LAA-yfg343")
    end

    it "returns the submission linked to the laa reference" do
      expect(helper.find_referred_submission("LAA-yfg343").is_a?(Submission)).to be true
      expect(helper.find_referred_submission("LAA-yfg343").id).to eq(submission_id)
    end
  end
end
