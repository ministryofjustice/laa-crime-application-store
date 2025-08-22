require "rails_helper"

RSpec.describe Presenters::V1::PriorAuthority::AdditionalCost do
  let(:submission) { create(:submission, :with_pa_version) }
  let(:record) { submission.latest_version.application["additional_costs"].first }

  describe "#base_cost" do
    context "when unit type is per item" do
      it "correctly calculates the base cost" do
        expect(described_class.new(record).total_cost).to eq(20)
      end
    end

    context "when quote unit type is per hour" do
      let(:submission) { create(:submission, build_scope: [:with_per_hour_additional_cost_pa_application]) }

      it "correctly calculates the base cost" do
        expect(described_class.new(record).total_cost).to eq(30)
      end
    end
  end
end
