module V1
  module Nsm
    class DisbursementCostsPresenter
      def initialize(disbursement)
        @disbursement = disbursement
      end

      # TODO: CRM457-2747 - Make assessed costs not compulsory
      def data_for_calculation
        {
          disbursement_type: @disbursement["disbursement_type"],
          claimed_cost: BigDecimal(@disbursement["total_cost_without_vat"]),
          claimed_miles: BigDecimal(disbursement_miles),
          claimed_apply_vat: apply_vat?,
          assessed_cost: BigDecimal(0),
          assessed_miles: BigDecimal(0),
          assessed_apply_vat: apply_vat?,
        }
      end

      def apply_vat?
        @disbursement["apply_vat"].in?([true, "true"])
      end

      def disbursement_miles
        @disbursement["miles"].to_s.presence || 0
      end
    end
  end
end
