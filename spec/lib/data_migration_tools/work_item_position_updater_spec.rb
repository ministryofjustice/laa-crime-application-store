require "rails_helper"

RSpec.describe DataMigrationTools::WorkItemPositionUpdater do
  subject(:updater) { described_class.new(sub_ver) }

  let(:submission) { create(:submission) }
  let(:sub_ver) { create(:submission_version, submission:, version: 1, application: { work_items: }) }

  context "when work_items without positions exist on claim" do
    let(:work_items) do
      [
        build(:work_item, id: "bbb222", position: nil, completed_on: 2.days.ago.to_date.iso8601, work_type: { "value" => "waiting", "en" => "Waiting" }),
        build(:work_item, id: "bbb111", position: nil, completed_on: 3.days.ago.to_date.iso8601, work_type: { "value" => "travel", "en" => "Travel" }),
        build(:work_item, id: "aaa111", position: nil, completed_on: 3.days.ago.to_date.iso8601, work_type: { "value" => "attendance_with_counsel", "en" => "Attendance with counsel" }),
      ]
    end

    it "updates existing work items with sorted position value" do
      expect { updater.call }
        .to change { sub_ver.reload.application["work_items"] }
        .from(
          [
            hash_including({ "id" => "bbb222", "position" => nil }),
            hash_including({ "id" => "bbb111", "position" => nil }),
            hash_including({ "id" => "aaa111", "position" => nil }),
          ],
        )
        .to(
          [
            hash_including({ "id" => "bbb222", "position" => 3 }),
            hash_including({ "id" => "bbb111", "position" => 2 }),
            hash_including({ "id" => "aaa111", "position" => 1 }),
          ],
        )
    end

    it "does not update the objects timestamps" do
      travel_to(1.hour.ago) do
        sub_ver
      end

      expect { updater.call }.not_to change(sub_ver, :updated_at)
    end
  end

  context "when work_items do NOT exist on claim" do
    let(:work_items) { nil }

    it "does not raise an error" do
      expect { updater.call }.not_to raise_error
    end
  end

  context "when an error is encountered" do
    let(:work_items) { [build(:work_item)] }

    before do
      allow(sub_ver).to receive(:save!).and_raise StandardError, "oops, something went wrong!"
      allow(Rails.logger).to receive(:warn)
    end

    it "logs the error" do
      updater.call
      expect(Rails.logger).to have_received(:warn).with(/Encountered error updating work item position.*\n.*oops.*/)
    end
  end
end
