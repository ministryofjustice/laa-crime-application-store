require "rails_helper"

RSpec.describe PaymentRequestResource do
  def serialize_payment_request(payment_request, include_claim: true)
    JSON.parse(
      described_class
        .new(payment_request, params: { include_claim: include_claim })
        .serialize
    )
  end

  describe "#serialize" do
    context "when the payment request belongs to an NSM claim" do
      let(:submission_id) { SecureRandom.uuid }
      let(:payment_request) do
        build(:payment_request, :non_standard_magistrate).tap do |request|
          request.payment_request_claim.submission_id = submission_id
          request.claimed_total = 500
          request.allowed_total = 450
        end
      end

      it "exposes NSM specific cost attributes and suppresses assigned counsel ones" do
        serialized = serialize_payment_request(payment_request)

        %w[
          claimed_profit_cost
          allowed_profit_cost
          claimed_travel_cost
          allowed_travel_cost
          claimed_waiting_cost
          allowed_waiting_cost
          claimed_disbursement_cost
          allowed_disbursement_cost
          claimed_total
          allowed_total
        ].each { expect(serialized).to have_key(_1) }

        %w[
          claimed_net_assigned_counsel_cost
          claimed_assigned_counsel_vat
          allowed_net_assigned_counsel_cost
          allowed_assigned_counsel_vat
        ].each { expect(serialized).not_to have_key(_1) }

        expect(serialized["submission_id"]).to eq(submission_id)
      end

      it "serializes the linked NSM claim when include_claim is true" do
        serialized = serialize_payment_request(payment_request, include_claim: true)

        expect(serialized.fetch("payment_request_claim")).to include(
          "claim_type" => "NsmClaim"
        )
      end
    end

    context "when the payment request belongs to an Assigned Counsel claim" do
      let(:submission_id) { SecureRandom.uuid }
      let(:payment_request) do
        build(:payment_request, :assigned_counsel).tap do |request|
          request.payment_request_claim.submission_id = submission_id
          request.claimed_total = 400
          request.allowed_total = 350
        end
      end

      it "exposes assigned counsel attributes and hides NSM cost fields" do
        serialized = serialize_payment_request(payment_request)

        %w[
          claimed_net_assigned_counsel_cost
          claimed_assigned_counsel_vat
          allowed_net_assigned_counsel_cost
          allowed_assigned_counsel_vat
          claimed_total
          allowed_total
        ].each { expect(serialized).to have_key(_1) }

        %w[
          claimed_profit_cost
          claimed_travel_cost
          claimed_waiting_cost
          claimed_disbursement_cost
          allowed_profit_cost
          allowed_travel_cost
          allowed_waiting_cost
          allowed_disbursement_cost
        ].each { expect(serialized).not_to have_key(_1) }

        expect(serialized["submission_id"]).to eq(submission_id)
        expect(serialized.fetch("payment_request_claim")).to include(
          "claim_type" => "AssignedCounselClaim"
        )
      end
    end

    context "when include_claim is false" do
      let(:payment_request) { build(:payment_request, :non_standard_magistrate) }

      it "omits the payment_request_claim relationship" do
        serialized = serialize_payment_request(payment_request, include_claim: false)

        expect(serialized).not_to have_key("payment_request_claim")
      end
    end

    context "when the payment request is not linked to a supported claim" do
      let(:payment_request) do
        build(
          :payment_request,
          payment_request_claim: nil,
          claimed_total: 250,
          allowed_total: 200
        )
      end

      it "does not expose total fields that depend on a supported claim" do
        serialized = serialize_payment_request(payment_request, include_claim: false)

        expect(serialized).not_to have_key("claimed_total")
        expect(serialized).not_to have_key("allowed_total")
      end

      it "returns a nil submission_id gracefully" do
        serialized = serialize_payment_request(payment_request, include_claim: false)

        expect(serialized["submission_id"]).to be_nil
      end
    end
  end
end
