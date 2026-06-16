require "rails_helper"

RSpec.describe "Active Providers" do
  let(:base_date) { Date.new(2024, 6, 26) }
  let(:view_definition) { Rails.root.join("db/views/active_providers_v02.sql").read }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :active_providers
    end
  end

  it "calculates cumulative provider counts without a correlated submissions self-scan" do
    expect(view_definition).not_to match(/from\s+submissions\s+as\s+subs/i)
    expect(view_definition).not_to match(/select\s+count\s*\(\s*distinct\s*\(\s*subs\.office_code\s*\)\s*\)/i)
  end

  it "keeps the Metabase dashboard field names" do
    expected_fields = %w[
      application_type
      submitted_start
      office_codes_submitting_during_the_period
      total_office_codes_submitters
      office_codes_during_the_period
    ]

    expect(klass.column_names).to eq(expected_fields)
  end

  it "correctly calculates the total provider counts" do
    travel_to(base_date - 7) { create(:submission, :with_pa_version, account_number: "1A123B") }
    travel_to(base_date - 14) { create(:submission, :with_pa_version, account_number: "1A123B") }
    travel_to(base_date) { create(:submission, :with_pa_version, account_number: "B345FF") }
    travel_to(base_date - 7) { create(:submission, :with_pa_version, account_number: "B345FF") }

    expect(klass.all.map(&:attributes)).to eq([
      { "application_type" => "crm4",
        "office_codes_during_the_period" => %w[1A123B],
        "office_codes_submitting_during_the_period" => 1,
        "submitted_start" => Date.new(2024, 0o6, 10),
        "total_office_codes_submitters" => 1 },
      { "application_type" => "crm4",
        "office_codes_during_the_period" => %w[1A123B B345FF],
        "office_codes_submitting_during_the_period" => 2,
        "submitted_start" => Date.new(2024, 0o6, 17),
        "total_office_codes_submitters" => 2 },
      { "application_type" => "crm4",
        "office_codes_during_the_period" => %w[B345FF],
        "office_codes_submitting_during_the_period" => 1,
        "submitted_start" => Date.new(2024, 0o6, 24),
        "total_office_codes_submitters" => 2 },
    ])
  end

  it "splits by application_type" do
    travel_to(base_date) { create(:submission, :with_pa_version, account_number: "1A123B") }
    travel_to(base_date - 7) { create(:submission, :with_nsm_version, account_number: "1A123B") }
    travel_to(base_date - 14) { create(:submission, :with_pa_version, account_number: "1A123B") }
    travel_to(base_date) { create(:submission, :with_nsm_version, account_number: "B345FF") }
    travel_to(base_date - 7) { create(:submission, :with_nsm_version, account_number: "B345FF") }

    expect(klass.all.map(&:attributes)).to eq([
      { "application_type" => "crm4",
        "office_codes_during_the_period" => %w[1A123B],
        "office_codes_submitting_during_the_period" => 1,
        "submitted_start" => Date.new(2024, 0o6, 10),
        "total_office_codes_submitters" => 1 },
      { "application_type" => "crm4",
        "office_codes_during_the_period" => %w[1A123B],
        "office_codes_submitting_during_the_period" => 1,
        "submitted_start" => Date.new(2024, 0o6, 24),
        "total_office_codes_submitters" => 1 },
      { "application_type" => "crm7",
        "office_codes_during_the_period" => %w[1A123B B345FF],
        "office_codes_submitting_during_the_period" => 2,
        "submitted_start" => Date.new(2024, 0o6, 17),
        "total_office_codes_submitters" => 2 },
      { "application_type" => "crm7",
        "office_codes_during_the_period" => %w[B345FF],
        "office_codes_submitting_during_the_period" => 1,
        "submitted_start" => Date.new(2024, 0o6, 24),
        "total_office_codes_submitters" => 2 },
    ])
  end
end
