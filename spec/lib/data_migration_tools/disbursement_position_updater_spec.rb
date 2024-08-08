require "rails_helper"

RSpec.describe DataMigrationTools::DisbursementPositionUpdater do
  subject(:updater) { described_class.new(sub_ver) }

  let(:submission) { create(:submission) }
  let(:sub_ver) { create(:submission_version, submission:, version: 1, application: { disbursements: }) }

  context "when disbursements exist on claim" do
    let(:disbursements) do
      [
        build(:disbursement, id: "bbb222", position: nil, disbursement_date: 2.days.ago.to_date.iso8601, disbursement_type: { "en" => "Car mileage", "value" => "car" }),
        build(:disbursement, id: "bbb111", position: nil, disbursement_date: 3.days.ago.to_date.iso8601, disbursement_type: { "en" => "Car mileage", "value" => "car" }),
        build(:disbursement, id: "aaa111", position: nil, disbursement_date: 3.days.ago.to_date.iso8601, disbursement_type: { "en" => "Bike mileage", "value" => "bike" }),

        build(:disbursement,
              id: "bbb333",
              position: nil,
              disbursement_date: 2.days.ago.to_date.iso8601,
              disbursement_type: { "en" => "Other foobar", "value" => "other" },
              other_type: { "en" => "Facial Mapping Experts", "value" => "facial_mapping_experts" }),

        build(:disbursement,
              id: "bbb444",
              position: nil,
              disbursement_date: 1.day.ago.to_date.iso8601,
              disbursement_type: { "en" => "Other foobar", "value" => "other" },
              other_type: { "value" => "facial_mapping_experts" }),
      ]
    end

    it "updates existing disbursements with sorted position value" do
      expect { updater.call }
        .to change { sub_ver.reload.application["disbursements"] }
        .from(
          [
            hash_including({ "id" => "bbb222", "position" => nil }),
            hash_including({ "id" => "bbb111", "position" => nil }),
            hash_including({ "id" => "aaa111", "position" => nil }),
            hash_including({ "id" => "bbb333", "position" => nil }),
            hash_including({ "id" => "bbb444", "position" => nil }),
          ],
        )
        .to(
          [
            hash_including({ "id" => "bbb222", "position" => 3 }),
            hash_including({ "id" => "bbb111", "position" => 2 }),
            hash_including({ "id" => "aaa111", "position" => 1 }),
            hash_including({ "id" => "bbb333", "position" => 4 }),
            hash_including({ "id" => "bbb444", "position" => 5 }),
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

  context "when disbursements do NOT exist on claim" do
    let(:disbursements) { nil }

    it "does not raise an error" do
      expect { updater.call }.not_to raise_error
    end
  end
end
