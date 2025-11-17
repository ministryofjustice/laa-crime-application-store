require "rails_helper"

RSpec.describe PaymentRequest do
  describe "#nsm_claim=" do
    let(:payment_request) { build(:payment_request) }
    let(:nsm_claim) { build(:nsm_claim) }

    it "sets payment_request_claim to the given NsmClaim" do
      payment_request.nsm_claim = nsm_claim
      expect(payment_request.payment_request_claim).to eq(nsm_claim)
    end
  end

  describe "#assigned_counsel_claim=" do
    let(:payment_request) { build(:payment_request) }
    let(:assigned_counsel_claim) { build(:assigned_counsel_claim) }

    it "sets payment_request_claim to the given AssignedCounselClaim" do
      payment_request.assigned_counsel_claim = assigned_counsel_claim
      expect(payment_request.payment_request_claim).to eq(assigned_counsel_claim)
    end
  end

  context "when payment request is for an NsmClaim" do
    let(:payment_request) { create(:payment_request, :non_standard_magistrate) }

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
    let(:payment_request) { create(:payment_request, :assigned_counsel) }

    it "returns true when request type is compatible with assigned counsel" do
      payment_request.request_type = "assigned_counsel_amendment"
      expect(payment_request.correct_request_type).to be(true)
    end

    it "invalidates record when request type is not compatible with assigned counsel" do
      payment_request.request_type = "non_standard_magistrate"
      payment_request.validate
      expect(payment_request.valid?).to be(false)
    end

    it "invalidates record when request type is random" do
      payment_request.request_type = "garbage"
      payment_request.validate
      expect(payment_request.valid?).to be(false)
    end
  end

  describe "#is_linked_to_claim_when_submitted" do
    let(:submitted_at) { Time.zone.now }

    it "invalidates record if payment request is not linked to claim and submitted" do
      expect { create(:payment_request, payment_request_claim: nil, submitted_at: submitted_at) }
        .to raise_error ActiveRecord::RecordInvalid, "Validation failed: Submitted at a payment request must be linked to a claim to be submitted"
    end

    it "returns true when payment request is not linked to a claim or submitted" do
      payment_request = create(:payment_request, payment_request_claim: nil, submitted_at: nil)
      expect(payment_request.is_linked_to_claim_when_submitted).to be(true)
    end

    it "returns true when payment request is linked to a claim and submitted" do
      payment_request = create(
        :payment_request,
        :non_standard_magistrate,
        submitted_at: submitted_at,
      )
      expect(payment_request.is_linked_to_claim_when_submitted).to be(true)
    end
  end

  describe "#correct_request_type" do
    context "when linked to an NsmClaim" do
      let(:claim) { build(:nsm_claim) }

      context "with valid NSM request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::NSM_REQUEST_TYPES.first, payment_request_claim: claim) }

        it "is valid" do
          expect(payment_request).to be_valid
        end
      end

      context "with invalid NSM request type" do
        let(:payment_request) { build(:payment_request, request_type: "invalid_request", payment_request_claim: claim) }

        it "is invalid" do
          expect(payment_request).to be_invalid
        end
      end

      context "with invalid request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::ASSIGNED_COUNSEL_REQUEST_TYPES.first, payment_request_claim: claim) }

        it "adds an error about invalid request type" do
          payment_request.valid?
          expect(payment_request.errors[:request_type]).to include("invalid request type for a NsmClaim")
        end
      end
    end

    context "when linked to an AssignedCounselClaim" do
      let(:claim) { build(:assigned_counsel_claim) }

      context "with valid assigned counsel request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::ASSIGNED_COUNSEL_REQUEST_TYPES.first, payment_request_claim: claim) }

        it "is valid" do
          expect(payment_request).to be_valid
        end
      end

      context "with invalid request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::NSM_REQUEST_TYPES.first, payment_request_claim: claim) }

        it "adds an error about invalid request type" do
          payment_request.valid?
          expect(payment_request.errors[:request_type]).to include("invalid request type for a AssignedCounselClaim")
        end
      end
    end
  end
end
