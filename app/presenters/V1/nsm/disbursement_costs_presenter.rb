module V1
  module Nsm
    class DisbursementCostsPresenter
      def initialize(disbursement)
        @disbursement = disbursement
      end

      def data_for_calculation
        {
          disbursement_type: @disbursement["disbursement_type"],
          claimed_cost: @disbursement["total_cost_without_vat"],
          claimed_miles: BigDecimal(@disbursement["miles"].to_s),
          claimed_apply_vat: apply_vat?,
          assessed_cost: 0,
          assessed_miles: BigDecimal(0),
          assessed_apply_vat: apply_vat?,
        }
      end

      def apply_vat?
        @disbursement["apply_vat"].in?([true, "true"])
      end
    end
  end
end
