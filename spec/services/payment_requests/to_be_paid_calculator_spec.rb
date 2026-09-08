require "rails_helper"

RSpec.describe PaymentRequests::ToBePaidCalculator do
  describe ".call" do
    context "when calculation method is entered_to_be_paid" do
      it "returns the entered allowed total as the payable amount" do
        result = described_class.call(
          calculation_method: LaaCrimeFormsCommon::PaymentBasis::ENTERED_TO_BE_PAID,
          allowed_total: 150.0,
        )

        expect(result.allowed_total).to eq(150.to_d)
        expect(result.previous_allowed_total).to be_nil
        expect(result.payable_total).to eq(150.to_d)
        expect(result.calculation_method).to eq("entered_to_be_paid")
      end
    end

    context "when calculation method is calculated_difference" do
      it "returns the difference between entered and previous totals" do
        result = described_class.call(
          calculation_method: LaaCrimeFormsCommon::PaymentBasis::CALCULATED_DIFFERENCE,
          allowed_total: 200.0,
          previous_allowed_total: 150.0,
        )

        expect(result.allowed_total).to eq(200.to_d)
        expect(result.previous_allowed_total).to eq(150.to_d)
        expect(result.payable_total).to eq(50.to_d)
        expect(result.calculation_method).to eq("calculated_difference")
      end

      it "raises when previous total is missing" do
        expect {
          described_class.call(
            calculation_method: LaaCrimeFormsCommon::PaymentBasis::CALCULATED_DIFFERENCE,
            allowed_total: 200.0,
          )
        }.to raise_error(described_class::MissingPreviousPaymentError, /previous_allowed_total is required/)
      end

      it "raises when allowed total is missing" do
        expect {
          described_class.call(
            calculation_method: LaaCrimeFormsCommon::PaymentBasis::CALCULATED_DIFFERENCE,
            allowed_total: nil,
            previous_allowed_total: 100.0,
          )
        }.to raise_error(described_class::MissingAllowedTotalError, /allowed_total is required/)
      end
    end

    context "when calculation method is unknown" do
      it "raises an ArgumentError" do
        expect {
          described_class.call(
            calculation_method: "something_else",
            allowed_total: 100.0,
          )
        }.to raise_error(ArgumentError, /Unknown calculation method/)
      end
    end
  end
end
