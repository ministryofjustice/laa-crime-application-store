require "rails_helper"

RSpec.describe NsmClaim, type: :model do
  subject(:nsm_claim) { build(:nsm_claim) }

  describe "inheritance" do
    it "inherits from PaymentRequestClaim" do
      expect(described_class < PaymentRequestClaim).to be true
    end
  end

  describe "associations" do
    it "has one assigned_counsel_claim with correct class, scope, and dependency" do
      association = described_class.reflect_on_association(:assigned_counsel_claim)

      expect(association.macro).to eq(:has_one)
      expect(association.class_name).to eq("AssignedCounselClaim")
      expect(association.foreign_key).to eq("nsm_claim_id")
      expect(association.options[:inverse_of]).to eq(:nsm_claim)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has one submission, dependent destroy" do
      association = described_class.reflect_on_association(:submission)

      expect(association.macro).to eq(:has_one)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with all required attributes" do
      expect(nsm_claim).to be_valid
    end

    it "uses OfficeCodeValidator on :office_code" do
      classes = described_class.validators_on(:solicitor_office_code).map(&:class)
      expect(classes).to include(OfficeCodeValidator)
    end

    context "with presence validations" do
      %i[
        laa_reference
        solicitor_firm_name
        client_first_name
        client_last_name
        outcome_code
        matter_type
        court_name
        ufn
        work_completed_date
        date_received
      ].each do |attr|
        it "is invalid without #{attr}" do
          nsm_claim.public_send("#{attr}=", nil)
          expect(nsm_claim).to be_invalid
          expect(nsm_claim.errors[attr]).to include("can't be blank")
        end
      end
    end

    context "with youth_court inclusion" do
      it "is valid when true" do
        nsm_claim.youth_court = true
        expect(nsm_claim).to be_valid
      end

      it "is valid when false" do
        nsm_claim.youth_court = false
        expect(nsm_claim).to be_valid
      end

      it "is invalid when nil" do
        nsm_claim.youth_court = nil
        expect(nsm_claim).to be_invalid
        expect(nsm_claim.errors[:youth_court]).to include("is not included in the list")
      end
    end

    context "with stage_code format" do
      it "is valid with 'PROG'" do
        nsm_claim.stage_code = "PROG"
        expect(nsm_claim).to be_valid
      end

      it "is valid with 'PROM'" do
        nsm_claim.stage_code = "PROM"
        expect(nsm_claim).to be_valid
      end

      it "is invalid with any other value" do
        nsm_claim.stage_code = "INVALID"
        expect(nsm_claim).to be_invalid
        expect(nsm_claim.errors[:stage_code]).to include("is invalid")
      end
    end

    context "with numericality" do
      it "is invalid if court_attendances is not an integer" do
        nsm_claim.court_attendances = "abc"
        expect(nsm_claim).to be_invalid
        expect(nsm_claim.errors[:court_attendances]).to include("is not a number")
      end

      it "is invalid if no_of_defendants is not an integer" do
        nsm_claim.no_of_defendants = "xyz"
        expect(nsm_claim).to be_invalid
        expect(nsm_claim.errors[:no_of_defendants]).to include("is not a number")
      end

      it "is valid if both are integers" do
        nsm_claim.court_attendances = 2
        nsm_claim.no_of_defendants = 3
        expect(nsm_claim).to be_valid
      end
    end
  end

  describe "dependent destroy" do
    let!(:nsm_claim) { create(:nsm_claim) }

    before do
      create(:assigned_counsel_claim, nsm_claim: nsm_claim)
      create(:submission, nsm_claim: nsm_claim)
    end

    it "destroys the assigned_counsel_claim when destroyed" do
      expect { nsm_claim.destroy }.to change(AssignedCounselClaim, :count).by(-1)
    end

    it "destroys the submission when destroyed" do
      expect { nsm_claim.destroy }.to change(Submission, :count).by(-1)
    end
  end
end
