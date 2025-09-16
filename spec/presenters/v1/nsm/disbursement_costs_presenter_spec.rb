require "rails_helper"

RSpec.describe V1::Nsm::DisbursementCostsPresenter do
  describe "#data_for_calculation" do
    context "when disbursement type is other (no miles)" do
      let(:application) { build(:application, :with_other_disbursement) }
      let(:disbursement) { application[:disbursements].first }

      it "default miles to 0 if value for miles is empty string" do
        expect { described_class.new(disbursement).data_for_calculation }.not_to raise_error
      end
    end
  end
end
