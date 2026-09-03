require "rails_helper"

RSpec.describe PaymentRequests::ToBePaidCalculator do
  subject(:call) { described_class.new(payment_requests:, cutoff_date:).call }

  let(:cutoff_date) { Date.new(2026, 9, 19) }
  let(:payment_requests) do
    [
      {
        request_type: "non_standard_magistrate",
        submitted_at: "2026-09-18 10:31:07 UTC",
        claimed_total: 130,
        allowed_total: 120,
      },
      {
        request_type: "non_standard_mag_amendment",
        submitted_at: "2026-09-19 10:31:07 UTC",
        claimed_total: 200,
        allowed_total: 150,
      },
    ]
  end

  context "when latest linked payment request is before the cutoff date" do
    let(:payment_requests) do
      [
        {
          request_type: "non_standard_magistrate",
          submitted_at: "2026-09-10 10:31:07 UTC",
          claimed_total: 130,
          allowed_total: 120,
        },
        {
          request_type: "non_standard_mag_amendment",
          submitted_at: "2026-09-18 10:31:07 UTC",
          claimed_total: 200,
          allowed_total: 150,
        },
      ]
    end

    it "returns the latest payment request totals" do
      expect(call).to include(
        claimed_total: 200,
        allowed_total: 150,
      )
    end
  end

  context "when latest linked payment request is on or after the cutoff date" do
    it "returns the total differences between latest and previous requests" do
      expect(call).to include(
        claimed_total: 70.to_d,
        allowed_total: 30.to_d,
      )
    end
  end

  context "when non-linked payment request types are present" do
    let(:payment_requests) do
      [
        {
          request_type: "assigned_counsel",
          submitted_at: "2026-09-30 10:31:07 UTC",
          claimed_total: 999,
          allowed_total: 999,
        },
        {
          request_type: "non_standard_magistrate",
          submitted_at: "2026-09-18 10:31:07 UTC",
          claimed_total: 130,
          allowed_total: 120,
        },
        {
          request_type: "non_standard_mag_appeal",
          submitted_at: "2026-09-20 10:31:07 UTC",
          claimed_total: 200,
          allowed_total: 150,
        },
      ]
    end

    it "calculates totals using only linked NSM family payment requests" do
      expect(call).to include(
        claimed_total: 70.to_d,
        allowed_total: 30.to_d,
      )
    end
  end

  context "when there is no previous linked payment request after the cutoff date" do
    let(:payment_requests) do
      [
        {
          request_type: "non_standard_mag_appeal",
          submitted_at: "2026-09-20 10:31:07 UTC",
          claimed_total: 200,
          allowed_total: 150,
        },
      ]
    end

    it "returns latest totals" do
      expect(call).to include(
        claimed_total: 200,
        allowed_total: 150,
      )
    end
  end
end
