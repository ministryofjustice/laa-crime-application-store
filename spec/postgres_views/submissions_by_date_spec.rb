require "rails_helper"

RSpec.describe "submissions_by_date" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :submissions_by_date
    end
  end

  it "reports submissions and resubmissions for a given date" do
    submission = create(:submission, auto_create_version: false)
    create(:submission_version, status: "submitted", created_at: 1.day.ago, submission: submission)

    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 0, "total" => 1 },
    ])
    submission_2 = create(:submission, auto_create_version: false)
    create(:submission_version, status: "submitted", created_at: 2.days.ago, submission: submission_2)
    create(:submission_version, status: "provider_updated", created_at: 1.day.ago, submission: submission_2)

    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 2.days.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 0, "total" => 1 },
      { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 1, "total" => 2 },
    ])
  end

  it "can be resubmitted multiple times on the same day" do
    submission = create(:submission, auto_create_version: false)
    create(:submission_version, status: "submitted", created_at: 1.day.ago, submission: submission)
    create(:submission_version, status: "provider_updated", created_at: 1.day.ago, submission: submission)
    create(:submission_version, status: "provider_updated", created_at: 1.day.ago, submission: submission)
    expect(klass.all.map(&:attributes)).to eq([
      { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 2, "total" => 3 },
    ])
  end
end
