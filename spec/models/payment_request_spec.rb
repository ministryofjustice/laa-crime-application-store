require "rails_helper"

RSpec.describe PaymentRequest do
  describe "#correct_request_type" do
    context "when payment request is for an NsmClaim" do
      let(:claim) { create(:nsm_claim) }
      let(:payment_request) { create(:payment_request, payable: claim) }

      it "returns true when request type is compatible with non-standard mag" do
        payment_request.request_type = "non_standard_mag_appeal"
        expect(payment_request.correct_request_type).to be(true)
      end

      it "invalidates record when request type is not compatible with non-standard mag" do
        payment_request.request_type = "assigned_counsel"
        payment_request.validate
        expect(payment_request.valid?).to be(false)
      end

      it "invalidates record when request type is random" do
        payment_request.request_type = "garbage"
        payment_request.validate
        expect(payment_request.valid?).to be(false)
      end
    end

    context "when payment request is for an AssignedCounselClaim" do
      let(:claim) { create(:assigned_counsel_claim) }
      let(:payment_request) { create(:payment_request, request_type: "assigned_counsel", payable: claim) }

      it "returns true when request type is compatible with assigned counsel" do
        payment_request.request_type = "assigned_counsel_amendment"
        expect(payment_request.correct_request_type).to be(true)
      end

      it "invalidates record when request type is not compatible with assigned counsel" do
        payment_request.request_type = "non_standard_mag"
        payment_request.validate
        expect(payment_request.valid?).to be(false)
      end

      it "invalidates record when request type is random" do
        payment_request.request_type = "garbage"
        payment_request.validate
        expect(payment_request.valid?).to be(false)
      end
    end
  end

  describe "#is_linked_to_claim_when_submitted" do
    let(:submitted_at) { Time.zone.now }

    it "invalidates record if payment request is not linked to claim and submitted" do
      expect { create(:payment_request, :non_standard_mag, payable: nil, submitted_at: submitted_at) }
        .to raise_error ActiveRecord::RecordInvalid, "Validation failed: Submitted at a payment request must be linked to a claim to be submitted"
    end

    it "returns true when payment request is not linked to a claim or submitted" do
      payment_request = create(:payment_request, :non_standard_mag, payable: nil, submitted_at: nil)
      expect(payment_request.is_linked_to_claim_when_submitted).to be(true)
    end

    it "returns true when payment request is linked to a claim and submitted" do
      payment_request = create(
        :payment_request,
        :non_standard_mag,
        payable: create(:nsm_claim),
        submitted_at: submitted_at,
      )
      expect(payment_request.is_linked_to_claim_when_submitted).to be(true)
    end
  end
end
