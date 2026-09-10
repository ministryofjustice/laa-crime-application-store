require "rails_helper"

RSpec.describe PayableClaimResource do
  def serialize_claim(claim)
    JSON.parse(described_class.new(claim).serialize)
  end

  describe "#serialize" do
    context "when serializing an NSM claim" do
      let(:claim) do
        create(
          :nsm_claim,
          stage_code: "PROG",
          outcome_code: "CP01",
          court_attendances: 4,
          no_of_defendants: 2,
          original_submission_date: Date.new(2026, 9, 1),
          client_first_name: "Jimmy",
          client_last_name: "Jones",
          submission_id: SecureRandom.uuid,
        )
      end

      before do
        create(:payment_request, :non_standard_magistrate, payable_claim: claim)
      end

      it "includes mapped NSM fields and excludes assigned counsel fields" do
        serialized = serialize_claim(claim)

        expect(serialized["type"]).to eq("NsmClaim")
        expect(serialized["stage_reached"]).to eq("PROG")
        expect(serialized["hearing_outcome_code"]).to eq("CP01")
        expect(serialized["number_of_attendances"]).to eq(4)
        expect(serialized["number_of_defendants"]).to eq(2)
        expect(serialized["original_submission_month"]).to eq(9)
        expect(serialized["original_submission_year"]).to eq(2026)
        expect(serialized["defendant_first_name"]).to eq("Jimmy")
        expect(serialized["defendant_last_name"]).to eq("Jones")
        expect(serialized).not_to have_key("counsel_office_code")
        expect(serialized).not_to have_key("counsel_firm_name")
      end
    end

    context "when serializing an assigned counsel claim" do
      let(:claim) do
        create(
          :assigned_counsel_claim,
          counsel_office_code: "2C123B",
          counsel_firm_name: "Counsel Firm",
          client_last_name: "Smith",
        )
      end

      before do
        create(:payment_request, :assigned_counsel, payable_claim: claim)
      end

      it "includes assigned counsel fields and excludes NSM-only fields" do
        serialized = serialize_claim(claim)

        expect(serialized["type"]).to eq("AssignedCounselClaim")
        expect(serialized["defendant_last_name"]).to eq("Smith")
        expect(serialized["counsel_office_code"]).to eq("2C123B")
        expect(serialized["counsel_firm_name"]).to eq("Counsel Firm")
        expect(serialized).not_to have_key("stage_reached")
        expect(serialized).not_to have_key("hearing_outcome_code")
        expect(serialized).not_to have_key("number_of_attendances")
        expect(serialized).not_to have_key("number_of_defendants")
      end
    end

    context "when NSM original submission date is missing" do
      let(:claim) { build(:nsm_claim, original_submission_date: nil) }

      it "returns nil for original submission month and year" do
        serialized = serialize_claim(claim)

        expect(serialized["original_submission_month"]).to be_nil
        expect(serialized["original_submission_year"]).to be_nil
      end
    end
  end
end
