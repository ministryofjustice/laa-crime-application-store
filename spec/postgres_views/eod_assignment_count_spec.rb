require "rails_helper"

RSpec.describe "submissions_by_date" do
  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = :eod_assignment_count
    end
  end
  let(:period) { (2.days.ago.to_date..Date.today) }
  # NOTE: to ignore daylight-saving; 2 days ago: 70-50, 1 day ago: 46-26, today: 22-2
  let(:singuarlity) { Time.zone.now.end_of_day }

  it "assignable without asisgnment" do
    create(
      :event_submission,
      events: [{ id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours }]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 1, "assigned" => 0 },
      { "day" => 1.day.ago.to_date, "assignable" => 1, "assigned" => 0 },
      { "day" => 0.day.ago.to_date, "assignable" => 1, "assigned" => 0 }
    ])
  end

  it "assignable with decision, without assignment" do
    create(
      :event_submission,
      events: [
        { id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours },
        { id: 2, event_type: 'decision', created_at: singuarlity - 40.hours }
      ]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 1, "assigned" => 0 },
      { "day" => 1.day.ago.to_date, "assignable" => 0, "assigned" => 0 },
      { "day" => 0.day.ago.to_date, "assignable" => 0, "assigned" => 0 }
    ])
  end

  it "assignable with assignment and unassignment" do
    create(
      :event_submission,
      events: [
        { id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours },
        { id: 2, event_type: 'assignment', created_at: singuarlity - 65.hours },
        { id: 3, event_type: 'unassignment', created_at: singuarlity - 40.hours }
      ]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 1, "assigned" => 1 },
      { "day" => 1.day.ago.to_date, "assignable" => 1, "assigned" => 0 },
      { "day" => 0.day.ago.to_date, "assignable" => 1, "assigned" => 0 }
    ])
  end

  it "assignable with multiple assignment and unassignment" do
    create(
      :event_submission,
      events: [
        { id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours },
        { id: 2, event_type: 'assignment', created_at: singuarlity - 65.hours },
        { id: 3, event_type: 'unassignment', created_at: singuarlity - 40.hours },
        { id: 4, event_type: 'assignment', created_at: singuarlity - 35.hours }
      ]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 1, "assigned" => 1 },
      { "day" => 1.day.ago.to_date, "assignable" => 1, "assigned" => 1 },
      { "day" => 0.day.ago.to_date, "assignable" => 1, "assigned" => 1 }
    ])
  end

  it "multiple assignable (single application)" do
    create(
      :event_submission,
      events: [
        { id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours },
        { id: 2, event_type: 'assignment', created_at: singuarlity - 65.hours },
        { id: 3, event_type: 'sent_back', created_at: singuarlity - 60.hours },
        { id: 4, event_type: 'provider_updated', created_at: singuarlity - 45.hours },
        { id: 5, event_type: 'assignment', created_at: singuarlity - 20.hours }
      ]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 0, "assigned" => 0 },
      { "day" => 1.day.ago.to_date, "assignable" => 1, "assigned" => 0 },
      { "day" => 0.day.ago.to_date, "assignable" => 1, "assigned" => 1 }
    ])
  end

  it "multiple applications" do
    create(
      :event_submission,
      events: [
        { id: 1, event_type: 'new_version', created_at: singuarlity - 70.hours },
        { id: 2, event_type: 'assignment', created_at: singuarlity - 65.hours },
      ]
    )
    create(
      :event_submission,
      events: [
        { id: 4, event_type: 'new_version', created_at: singuarlity - 68.hours },
        { id: 5, event_type: 'assignment', created_at: singuarlity - 44.hours },
        { id: 6, event_type: 'unassignment', created_at: singuarlity - 19.hours },
      ]
    )
    expect(klass.where(day: period).map(&:attributes)).to eq([
      { "day" => 2.day.ago.to_date, "assignable" => 2, "assigned" => 1 },
      { "day" => 1.day.ago.to_date, "assignable" => 2, "assigned" => 2 },
      { "day" => 0.day.ago.to_date, "assignable" => 2, "assigned" => 1 }
    ])
  end
end