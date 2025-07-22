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
end
