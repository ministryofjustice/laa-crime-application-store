require "rails_helper"

RSpec.describe "submissions_by_date" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :submissions_by_date
    end
  end

  it "reports submissions and resubmissions for a given date" do
    create(
      :event_submission,
      events: [{ event_type: "new_version", created_at: 1.day.ago }],
    )
    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 1.day.ago.to_date, "submission" => 1, "resubmission" => 0, "total" => 1 },
    ])
    create(
      :event_submission,
      events: [
        { event_type: "new_version", created_at: 2.days.ago },
        { event_type: "provider_updated", created_at: 1.day.ago },
      ],
    )
    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 2.days.ago.to_date, "submission" => 1, "resubmission" => 0, "total" => 1 },
      { "event_on" => 1.day.ago.to_date, "submission" => 1, "resubmission" => 1, "total" => 2 },
    ])
  end

  it "can be resubmitted multiple times on the same day" do
    create(
      :event_submission,
      events: [
        { event_type: "new_version", created_at: 1.day.ago },
        { event_type: "provider_updated", created_at: 1.day.ago },
        { event_type: "provider_updated", created_at: 1.day.ago },
      ],
    )
    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 1.day.ago.to_date, "submission" => 1, "resubmission" => 2, "total" => 3 },
    ])
  end
end
