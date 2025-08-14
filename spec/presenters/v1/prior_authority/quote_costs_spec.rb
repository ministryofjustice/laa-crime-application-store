require "rails_helper"

RSpec.describe V1::PriorAuthority::QuoteCosts do
  let(:submission) { create(:submission, :with_pa_version) }
  let(:application) { submission.latest_version.application }
  let(:quote) { submission.latest_version.application["quotes"].first }

  describe "#base_cost" do
    context "when quote cost type is per hour" do
      it "correctly calculates the base cost" do
        expect(described_class.new(quote, application).base_cost).to eq(30)
      end
    end

    context "when quote cost type is per item" do
      let(:submission) { create(:submission, build_scope: [:with_per_item_quote_pa_application]) }

      it "correctly calculates the base cost" do
        expect(described_class.new(quote, application).base_cost).to eq(200)
      end
    end
  end
end
