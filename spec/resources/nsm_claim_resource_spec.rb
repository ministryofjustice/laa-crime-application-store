require "rails_helper"

RSpec.describe NsmClaimResource do
  def serialize_claim(claim)
    JSON.parse(described_class.new(claim).serialize)
  end

  describe "#serialize" do
    context "when original submission date is present" do
      let(:claim) do
        create(
          :nsm_claim,
          original_submission_date: Date.new(2026, 8, 1),
        )
      end

      before do
        create(:payment_request, :non_standard_magistrate, payable_claim: claim)
      end

      it "serializes month/year and payment requests without nested claim payloads" do
        serialized = serialize_claim(claim).fetch("nsm_claim")

        expect(serialized["claim_type"]).to eq("NsmClaim")
        expect(serialized["original_submission_month"]).to eq(8)
        expect(serialized["original_submission_year"]).to eq(2026)
        expect(serialized.fetch("payment_requests")).not_to be_empty
        expect(serialized.fetch("payment_requests").first).not_to have_key("payable_claim")
      end
    end

    context "when original submission date is nil" do
      let(:claim) { build(:nsm_claim, original_submission_date: nil) }

      it "returns nil month/year values" do
        serialized = serialize_claim(claim).fetch("nsm_claim")

        expect(serialized["original_submission_month"]).to be_nil
        expect(serialized["original_submission_year"]).to be_nil
      end
    end
  end
end
