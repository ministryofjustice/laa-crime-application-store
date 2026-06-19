require "rails_helper"

RSpec.describe "Assigned counsel payments" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :assigned_counsel_payments
    end
  end

  it "projects CRM8 payment request fields needed by the finance dashboard" do
    claim = create(
      :assigned_counsel_claim,
      client_first_name: "Ada",
      client_last_name: "Lovelace",
      counsel_firm_name: "Counsel Chambers",
      counsel_office_code: "1C234D",
      ufn: "120423/001",
    )

    travel_to(Time.zone.local(2026, 1, 20, 10, 30)) do
      create(
        :payment_request,
        :assigned_counsel,
        payable_claim: claim,
        claimed_net_assigned_counsel_cost: 500,
        claimed_assigned_counsel_vat: 100,
        claimed_total: 600,
        allowed_net_assigned_counsel_cost: 450,
        allowed_assigned_counsel_vat: 90,
        allowed_total: 540,
        date_claim_assessed: Date.new(2026, 1, 19),
      )
    end

    expect(klass.take.attributes).to include(
      "description" => "CRM8",
      "invoice_type" => "CL_CON_CWA",
      "client_name" => "Ada Lovelace",
      "case_reference" => "120423/001",
      "date_requested" => Date.new(2026, 1, 19),
      "office_code" => "1C234D",
      "invoice_amount_inc_vat" => 540,
      "tax_amount_percentage" => 20,
      "fee_type" => "Profit costs",
      "provider_reference" => "Counsel Chambers",
      "payment_type" => "AC",
      "claimed_net_assigned_counsel_cost" => 500,
      "claimed_assigned_counsel_vat" => 100,
      "allowed_net_assigned_counsel_cost" => 450,
      "allowed_assigned_counsel_vat" => 90,
    )
  end

  it "maps assigned counsel variants and excludes non CRM8 payment requests" do
    create(:payment_request, :non_standard_magistrate)
    create(:payment_request, :assigned_counsel)
    create(:payment_request, :assigned_counsel_appeal)
    create(:payment_request, :assigned_counsel_amendment)

    expect(klass.pluck(:payment_type)).to contain_exactly(
      "AC",
      "AC Appeal",
      "AC Amendment",
    )
  end
end
