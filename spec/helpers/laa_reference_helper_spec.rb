require "rails_helper"

RSpec.describe LaaReferenceHelper, type: :helper do
  describe "#generate_laa_reference" do
    let(:ref_suffix) { "abc123" }

    before do
      allow(SecureRandom).to receive(:alphanumeric).and_return(ref_suffix)
      create(:nsm_claim, laa_reference: "LAA-#{ref_suffix}")
    end

    it "timeouts if trying to generate an laa reference that exists" do
      expect { Timeout.timeout(2) { helper.generate_laa_reference } }
        .to raise_error(Timeout::Error)
    end
  end

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

  describe "#find_referred_claim" do
    let(:laa_reference) { "LAA-ABC123" }

    context "when the laa_reference matches an NsmClaim" do
      let!(:nsm_claim) { create(:nsm_claim, laa_reference: laa_reference) }

      it "returns the matching NsmClaim" do
        result = find_referred_claim(laa_reference)
        expect(result).to eq(nsm_claim)
      end
    end

    context "when the laa_reference matches an AssignedCounselClaim" do
      let!(:assigned_counsel_claim) { create(:assigned_counsel_claim, laa_reference: laa_reference) }

      it "returns the matching AssignedCounselClaim" do
        result = find_referred_claim(laa_reference)
        expect(result).to eq(assigned_counsel_claim)
      end
    end

    context "when no claim matches the laa_reference" do
      it "returns nil" do
        result = find_referred_claim("LAA-NOTFOUND")
        expect(result).to be_nil
      end
    end

    context "when both claim types exist but only one matches" do
      before do
        create(:nsm_claim, laa_reference: "LAA-OTHER")
      end

      let!(:assigned_counsel_claim) { create(:assigned_counsel_claim, laa_reference: laa_reference) }

      it "returns the matching one only" do
        result = find_referred_claim(laa_reference)
        expect(result).to eq(assigned_counsel_claim)
      end
    end
  end
end
