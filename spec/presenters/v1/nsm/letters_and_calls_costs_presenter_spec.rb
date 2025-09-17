require "rails_helper"

RSpec.describe V1::Nsm::LettersAndCallsCostsPresenter do
  describe "#data_for_calculation" do
    context "when disbursement type is other (no miles)" do
      # let(:submission)
      let(:claim) { build(:application, :nsm) }

      it "successfully generates calculation values for letters" do
        expect(described_class.new(claim).calls_for_calculation).to eq({
          type: :calls,
          claimed_items: 220,
          claimed_uplift_percentage: 20,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        })
      end

      it "successfully generates calculation values for calls" do
        expect(described_class.new(claim).letters_for_calculation).to eq({
          type: :letters,
          claimed_items: 500,
          claimed_uplift_percentage: 10,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        })
      end
    end
  end
end
