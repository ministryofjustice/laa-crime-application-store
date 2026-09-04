require "rails_helper"

RSpec.describe PaymentRequest do
  describe "payment_basis validation" do
    it "accepts known payment basis values" do
      LaaCrimeFormsCommon::PaymentBasis::ALL.each do |value|
        payment_request = build(:payment_request, :non_standard_magistrate, payment_basis: value)

        expect(payment_request).to be_valid
      end
    end

    it "allows nil while legacy records are present" do
      payment_request = build(:payment_request, :non_standard_magistrate, payment_basis: nil)

      expect(payment_request).to be_valid
    end

    describe "calculation_method validation" do
      it "accepts known calculation method values" do
        LaaCrimeFormsCommon::PaymentBasis::CALCULATION_METHOD_BY_BASIS.values.uniq.each do |value|
          payment_request = build(:payment_request, :non_standard_magistrate, calculation_method: value)

          expect(payment_request).to be_valid
        end
      end

      it "allows nil while legacy records are present" do
        payment_request = build(:payment_request, :non_standard_magistrate, calculation_method: nil)

        expect(payment_request).to be_valid
      end

      it "rejects unknown values" do
        payment_request = build(:payment_request, :non_standard_magistrate, calculation_method: "not_valid")
        payment_request.validate

        expect(payment_request.errors[:calculation_method]).to include("is not included in the list")
      end

      it "rejects methods that do not match payment_basis" do
        payment_request = build(
          :payment_request,
          :non_standard_magistrate,
          payment_basis: "existing_payment_record",
          calculation_method: "entered_to_be_paid",
        )
        payment_request.validate

        expect(payment_request.errors[:calculation_method]).to include("must match payment_basis")
      end
    end

    it "rejects unknown values" do
      payment_request = build(:payment_request, :non_standard_magistrate, payment_basis: "not_valid")
      payment_request.validate

      expect(payment_request.errors[:payment_basis]).to include("is not included in the list")
    end
  end

  describe "entered_allowed_total validation" do
    it "accepts numeric values" do
      payment_request = build(:payment_request, :non_standard_magistrate, entered_allowed_total: 123.45)

      expect(payment_request).to be_valid
    end

    it "rejects values outside allowed numeric limits" do
      payment_request = build(
        :payment_request,
        :non_standard_magistrate,
        entered_allowed_total: (NumericLimits::MAX_FLOAT + 1),
      )
      payment_request.validate

      expect(payment_request.errors[:entered_allowed_total].join).to include("less than or equal to")
    end
  end

  describe "#nsm_claim=" do
    let(:payment_request) { build(:payment_request) }
    let(:nsm_claim) { build(:nsm_claim) }

    it "sets payable_claim to the given NsmClaim" do
      payment_request.nsm_claim = nsm_claim
      expect(payment_request.payable_claim).to eq(nsm_claim)
    end
  end

  describe "#assigned_counsel_claim=" do
    let(:payment_request) { build(:payment_request) }
    let(:assigned_counsel_claim) { build(:assigned_counsel_claim) }

    it "sets payable_claim to the given AssignedCounselClaim" do
      payment_request.assigned_counsel_claim = assigned_counsel_claim
      expect(payment_request.payable_claim).to eq(assigned_counsel_claim)
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
    it "invalidates record if payment request is not linked to claim" do
      expect { create(:payment_request, payable_claim: nil) }
        .to raise_error ActiveRecord::RecordInvalid, "Validation failed: Payable claim must exist"
    end
  end

  describe "#correct_request_type" do
    context "when linked to an NsmClaim" do
      let(:claim) { build(:nsm_claim) }

      context "with valid NSM request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::NSM_REQUEST_TYPES.first, payable_claim: claim) }

        it "is valid" do
          expect(payment_request).to be_valid
        end
      end

      context "with invalid NSM request type" do
        let(:payment_request) { build(:payment_request, request_type: "invalid_request", payable_claim: claim) }

        it "is invalid" do
          expect(payment_request).to be_invalid
        end
      end

      context "with invalid request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::ASSIGNED_COUNSEL_REQUEST_TYPES.first, payable_claim: claim) }

        it "adds an error about invalid request type" do
          payment_request.valid?
          expect(payment_request.errors[:request_type]).to include("invalid request type for a NsmClaim")
        end
      end
    end

    context "when linked to an AssignedCounselClaim" do
      let(:claim) { build(:assigned_counsel_claim) }

      context "with valid assigned counsel request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::ASSIGNED_COUNSEL_REQUEST_TYPES.first, payable_claim: claim) }

        it "is valid" do
          expect(payment_request).to be_valid
        end
      end

      context "with invalid request type" do
        let(:payment_request) { build(:payment_request, request_type: PaymentRequest::NSM_REQUEST_TYPES.first, payable_claim: claim) }

        it "adds an error about invalid request type" do
          payment_request.valid?
          expect(payment_request.errors[:request_type]).to include("invalid request type for a AssignedCounselClaim")
        end
      end
    end
  end
end
