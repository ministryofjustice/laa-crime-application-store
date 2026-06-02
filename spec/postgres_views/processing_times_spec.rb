require "rails_helper"

RSpec.describe "processing times" do
  let(:base_time) { Time.zone.local(2024, 6, 26, 12) }
  let(:view_definition) { Rails.root.join("db/views/processing_times_v04.sql").read }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :processing_times
    end
  end

  it "uses an indexed previous-version lookup rather than windowing all versions" do
    expect(view_definition).to include("JOIN LATERAL")
    expect(view_definition).not_to match(/\bLAG\s*\(/i)
  end

  it "records draft to submitted when only one version" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }

    expect(klass.all.map(&:attributes)).to eq([
      { "application_type" => "crm4",
        "from_date" => Date.new(2024, 6, 26),
        "from_status" => "draft",
        "from_time" => Time.zone.local(2024, 6, 26, 11, 50),
        "id" => submission.id,
        "processing_seconds" => 600.0,
        "to_date" => Date.new(2024, 6, 26),
        "to_status" => "submitted",
        "to_time" => Time.zone.local(2024, 6, 26, 12),
        "version" => 1,
        "claim_imported" => false },
    ])
  end

  it "records time between versions" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }
    travel_to(base_time + 20.minutes) { create(:submission_version, :with_pa_application, submission:, status: "approved", version: 2) }

    expect(klass.count).to eq(2)

    expect(klass.all.map(&:attributes)).to include(
      { "application_type" => "crm4",
        "from_date" => Date.new(2024, 6, 26),
        "from_status" => "submitted",
        "from_time" => Time.zone.local(2024, 6, 26, 12),
        "id" => submission.id,
        "processing_seconds" => 1200.0,
        "to_date" => Date.new(2024, 6, 26),
        "to_status" => "approved",
        "to_time" => Time.zone.local(2024, 6, 26, 12, 20),
        "version" => 2,
        "claim_imported" => false },
    )
  end

  it "ignores pending versions when deriving the previous state" do
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }
    travel_to(base_time + 20.minutes) do
      create(:submission_version, :with_pa_application, submission:, status: "sent_back", pending: true, version: 2)
    end
    travel_to(base_time + 40.minutes) do
      create(:submission_version, :with_pa_application, submission:, status: "approved", version: 3)
    end

    expect(klass.find_by(version: 3).attributes).to include(
      "from_status" => "submitted",
      "from_time" => Time.zone.local(2024, 6, 26, 12),
      "processing_seconds" => 2400.0,
      "to_status" => "approved",
      "to_time" => Time.zone.local(2024, 6, 26, 12, 40),
    )
  end
end
