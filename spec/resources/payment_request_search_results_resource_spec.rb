require "rails_helper"

RSpec.describe PaymentRequestSearchResultsResource do
  def serialize_collection(payment_requests)
    JSON.parse(described_class.new(payment_requests).serialize)
  end

  describe "#serialize" do
    context "when payment requests are linked to claims" do
      let(:submission_id) { SecureRandom.uuid }
      let(:claim) { build(:nsm_claim, submission_id: submission_id) }
      let(:payment_request) do
        build(:payment_request, :non_standard_magistrate, payment_request_claim: claim)
      end

      it "embeds the claim summary via ClaimPaymentSearchResultsResource" do
        serialized = serialize_collection([payment_request])
        entry = serialized.first

        expect(entry.fetch("payment_request_claim")).to include(
          "claim_type" => "NsmClaim",
          "laa_reference" => claim.laa_reference,
        )
      end

      it "derives submission_id from the associated claim" do
        serialized = serialize_collection([payment_request])

        expect(serialized.first["submission_id"]).to eq(submission_id)
      end
    end

    context "when a payment request is not linked to a claim" do
      let(:payment_request) { build(:payment_request, payment_request_claim: nil) }

      it "renders nil for the claim and submission_id" do
        serialized = serialize_collection([payment_request])
        entry = serialized.first

        expect(entry["payment_request_claim"]).to be_nil
        expect(entry["submission_id"]).to be_nil
      end
    end
  end
end
