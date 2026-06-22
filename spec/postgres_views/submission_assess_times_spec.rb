require "rails_helper"

RSpec.describe "submission_assess_times" do
  let(:view_definition) { Rails.root.join("db/views/submission_assess_times_v03.sql").read }
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :submission_assess_times
    end
  end

  it "uses DISTINCT ON for first decision lookup" do
    expect(view_definition).to include("SELECT DISTINCT ON (application_version.application_id)")
    expect(view_definition).to include("ORDER BY application_version.application_id, application_version.created_at")
  end

  it "uses lateral assignment-event expansion scoped to base submissions" do
    expect(view_definition).to include("CROSS JOIN LATERAL jsonb_array_elements(application.caseworker_history_events)")
    expect(view_definition).to include("FROM base")
    expect(view_definition).not_to match(/GROUP BY\s+application_id,\s*application/i)
  end

  it "calculates submission assessment timings using first assignment and first final decision" do
    base_time = Time.zone.local(2026, 1, 15, 9, 0, 0)
    submission = travel_to(base_time) { create(:submission, :with_pa_version) }

    submission.update!(
      caseworker_history_events: [
        { "event_type" => "assignment", "created_at" => (base_time + 5.minutes).iso8601 },
        { "event_type" => "assignment", "created_at" => (base_time + 10.minutes).iso8601 },
      ],
    )

    travel_to(base_time + 30.minutes) do
      create(:submission_version, :with_pa_application, submission:, status: "granted", version: 2)
    end

    expect(klass.all.map(&:attributes)).to eq([
      { "id" => submission.id,
        "application_type" => "crm4",
        "submission_date" => base_time,
        "office_code" => "1A123B",
        "first_decision" => "granted",
        "first_decision_date" => base_time + 30.minutes,
        "first_assigned_date" => base_time + 5.minutes,
        "minutes_to_assign" => 5.0,
        "minutes_to_assess" => 25.0 },
    ])
  end
end
