require "rails_helper"

RSpec.describe "submission creation times" do
  let(:base_time) { Time.zone.local(2024, 6, 26, 12) }
  let(:view_definition_path) { Rails.root.join("db/views/submission_creation_times_v04.sql") }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :submission_creation_times
    end
  end

  it "uses a single non-pending first-submitted-version query shape" do
    expect(view_definition_path).to exist

    view_definition = view_definition_path.read

    expect(view_definition).to include("pending IS FALSE")
    expect(view_definition).to include("DISTINCT ON (application_id)")
    expect(view_definition).to include("ORDER BY application_id, version")
    expect(view_definition).not_to match(/GROUP BY\s+application_id/i)
  end

  it "records one submission creation row from the earliest submitted version" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version, account_number: "1A123B") }

    travel_to(base_time + 20.minutes) do
      create(:submission_version, :with_pa_application, submission:, version: 2, status: "submitted", account_number: "1A123B")
    end

    expect(klass.all.map(&:attributes)).to eq([
      { "application_id" => submission.id,
        "application_type" => "crm4",
        "draft_created_date" => Time.zone.local(2024, 6, 26, 11, 50),
        "office_code" => "1A123B",
        "submission_date" => Time.zone.local(2024, 6, 26, 12),
        "claim_imported" => false,
        "minutes_to_submit" => 10.0 },
    ])
  end

  it "ignores pending submitted versions" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version, account_number: "1A123B") }

    travel_to(base_time + 20.minutes) do
      create(:submission_version, :with_pa_application,
             submission:,
             version: 2,
             status: "submitted",
             pending: true,
             account_number: "1A123B")
    end

    expect(klass.count).to eq(1)
  end
end
