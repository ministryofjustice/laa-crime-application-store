require "rails_helper"

RSpec.describe "submissions_by_date" do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = :submissions_by_date
    end
  end

  context "when application type is crm7" do
    let(:application_type) { "crm7" }

    it "reports submissions and resubmissions for a given date" do
      create(
        :event_submission,
        application_type:,
        events: [{ event_type: "new_version", submission_version: 1, created_at: 1.day.ago }],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm7", "submission" => 1, "resubmission" => 0, "total" => 1 },
      ])
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 2.days.ago },
          { event_type: "new_version", submission_version: 2, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 2.days.ago.to_date, "application_type" => "crm7", "submission" => 1, "resubmission" => 0, "total" => 1 },
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm7", "submission" => 1, "resubmission" => 1, "total" => 2 },
      ])
    end

    it "can be resubmitted multiple times on the same day" do
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 1.day.ago },
          { event_type: "new_version", submission_version: 2, created_at: 1.day.ago },
          { event_type: "new_version", submission_version: 3, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm7", "submission" => 1, "resubmission" => 2, "total" => 3 },
      ])
    end

    it "does not use crm4 criteria for resubmissions" do
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 1.day.ago },
          { event_type: "provider_updated", submission_version: 2, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm7", "submission" => 1, "resubmission" => 0, "total" => 1 },
      ])
    end
  end

  context "when application type is crm4" do
    let(:application_type) { "crm4" }

    it "reports submissions and resubmissions for a given date" do
      create(
        :event_submission,
        application_type:,
        events: [{ event_type: "new_version", submission_version: 1, created_at: 1.day.ago }],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 0, "total" => 1 },
      ])
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 2.days.ago },
          { event_type: "provider_updated", submission_version: 2, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 2.days.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 0, "total" => 1 },
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 1, "total" => 2 },
      ])
    end

    it "can be resubmitted multiple times on the same day" do
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 1.day.ago },
          { event_type: "provider_updated", submission_version: 2, created_at: 1.day.ago },
          { event_type: "provider_updated", submission_version: 3, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 2, "total" => 3 },
      ])
    end

    it "does not use crm4 criteria for resubmissions" do
      create(
        :event_submission,
        application_type:,
        events: [
          { event_type: "new_version", submission_version: 1, created_at: 1.day.ago },
          { event_type: "new_version", submission_version: 2, created_at: 1.day.ago },
        ],
      )
      expect(klass.all.map(&:attributes)).to eq([
        { "event_on" => 1.day.ago.to_date, "application_type" => "crm4", "submission" => 1, "resubmission" => 0, "total" => 1 },
      ])
    end
  end
end
