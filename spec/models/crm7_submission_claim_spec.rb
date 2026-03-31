require "rails_helper"

RSpec.describe Crm7SubmissionClaim do
  subject(:claim) { described_class.new(raw_payload) }

  let(:application_data) do
    {
      laa_reference: "LAA-CRM7001",
      ufn: "120223/001",
      firm_office: { account_number: "1A123B", name: "Firm & Sons" },
      defendants: [
        { first_name: "Jane", last_name: "Roe", main: false },
        { first_name: "John", last_name: "Doe", main: true },
      ],
      work_completed_date: Date.new(2024, 1, 1),
      matter_type: "13",
      youth_court: true,
      stage_reached: "PROG",
      stage_code: nil,
      outcome_code: nil,
      hearing_outcome: "CP17",
      court_attendances: 2,
      defendants_count: 2,
      court: "Ely",
    }
  end

  let(:raw_payload) do
    {
      id: "sub-123",
      created_at: Time.zone.parse("2024-01-01"),
      last_updated_at: Time.zone.parse("2024-01-02"),
      application: application_data,
    }
  end

  it "derives identifiers and solicitor details" do
    expect(claim.id).to eq("sub-123")
    expect(claim.laa_reference).to eq("LAA-CRM7001")
    expect(claim.solicitor_office_code).to eq("1A123B")
    expect(claim.solicitor_firm_name).to eq("Firm & Sons")
  end

  it "selects the main defendant" do
    expect(claim.client_last_name).to eq("Doe")
  end

  it "counts defendants and exposes application metrics" do
    expect(claim.ufn).to eq("120223/001")
  end
end
