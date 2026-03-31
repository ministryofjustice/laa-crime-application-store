require "rails_helper"

RSpec.describe Crm7SearchResult do
  subject(:result) { described_class.new(raw_record) }

  let(:raw_record) do
    {
      application_id: "app-123",
      application_type: "crm7",
      application: {
        laa_reference: "LAA-CRM7001",
        firm_office: { account_number: "1A123B", name: "Firm" },
        defendants: [{ first_name: "Jane", last_name: "Doe", main: true }],
        ufn: "120223/001",
      },
    }
  end

  it "exposes identifiers and delegates claim data" do
    expect(result.id).to eq("app-123")
    expect(result.submission_id).to eq("app-123")
    expect(result.laa_reference).to eq("LAA-CRM7001")
    expect(result.ufn).to eq("120223/001")
    expect(result.type).to eq("Crm7SubmissionClaim")
  end

  it "exposes solicitor and defendant information" do
    expect(result.solicitor_office_code).to eq("1A123B")
    expect(result.solicitor_firm_name).to eq("Firm")
    expect(result.defendant_last_name).to eq("Doe")
  end

  it "exposes request metadata" do
    expect(result.request_type).to eq("crm7")
  end

  context "when application_id is missing" do
    let(:raw_record) { super().merge(application_id: nil, id: "fallback-id") }

    it "falls back to the id key" do
      expect(result.id).to eq("fallback-id")
    end
  end
end
