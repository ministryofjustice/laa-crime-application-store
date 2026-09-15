require "rails_helper"

RSpec.describe "nsm payments" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :nsm_payments
    end
  end

  it "marks contingency Y and totals nil when prior totals are unavailable and to-be-paid is entered directly" do
    claim = create(:nsm_claim, solicitor_office_code: "1A234B", solicitor_firm_name: "Firm One", laa_reference: "LAA-123")

    create(
      :payment_request,
      :non_standard_mag_appeal,
      payable_claim: claim,
      payment_basis: "linked_no_original_payment",
      calculation_method: "entered_to_be_paid",
      allowed_total: 300,
      payable_total: 120,
    )

    expect(klass.take.attributes).to include(
      "contingency" => "Y",
      "totals" => nil,
      "to_be_paid" => 120,
      "office_code" => "1A234B",
      "office_name" => "Firm One",
      "laa_reference" => "LAA-123",
    )
  end

  it "marks contingency N and keeps totals when previous totals are available and payment is calculated" do
    claim = create(:nsm_claim)
    create(
      :payment_request,
      :non_standard_magistrate,
      payable_claim: claim,
      payment_basis: "standard_manual_entry",
      calculation_method: "entered_to_be_paid",
      allowed_total: 150,
      payable_total: 150,
      submitted_at: Time.zone.parse("2026-01-01 10:00:00 UTC"),
    )

    create(
      :payment_request,
      :non_standard_mag_supplemental,
      payable_claim: claim,
      payment_basis: "existing_payment_record",
      calculation_method: "calculated_difference",
      allowed_total: 210,
      payable_total: 60,
      submitted_at: Time.zone.parse("2026-01-02 10:00:00 UTC"),
    )

    latest = klass.order(submitted_at: :desc).first

    expect(latest.attributes).to include(
      "contingency" => "N",
      "totals" => 210,
      "to_be_paid" => 60,
      "request_type" => "non_standard_mag_supplemental",
    )
  end

  it "preserves genuine zero totals rather than coercing to nil" do
    claim = create(:nsm_claim)
    create(
      :payment_request,
      :non_standard_mag_amendment,
      payable_claim: claim,
      payment_basis: "existing_payment_record",
      calculation_method: "calculated_difference",
      allowed_total: 0,
      payable_total: 0,
    )

    row = klass.take

    expect(row.totals).to eq(0)
    expect(row.to_be_paid).to eq(0)
    expect(row.contingency).to eq("N")
  end

  it "exposes payment_request_id so grouped exports can sort deterministically within provider and claim" do
    claim = create(:nsm_claim, solicitor_office_code: "9Z999Z", laa_reference: "LAA-GROUP")
    payment_request = create(:payment_request, :non_standard_magistrate, payable_claim: claim)

    expect(klass.take.attributes).to include(
      "payment_request_id" => payment_request.id,
      "office_code" => "9Z999Z",
      "laa_reference" => "LAA-GROUP",
    )
  end
end
