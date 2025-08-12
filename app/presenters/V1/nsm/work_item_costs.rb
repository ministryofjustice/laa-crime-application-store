module V1
  module Nsm
    class WorkItemCosts
      def initialize(work_item, claim)
        @work_item = work_item
        @claim = claim
      end

      def allow_uplift?
        @claim["reasons_for_claim"].include?(ReasonForClaim::ENHANCED_RATES_CLAIMED.to_s)
      end

      def total_cost
        calculation[:claimed_total_exc_vat]
      end

      def allowed_total_cost
        calculation[:assessed_total_exc_vat]
      end

      def data_for_calculation
        {
          claimed_time_spent_in_minutes: @work_item["time_spent"]&.to_i,
          claimed_work_type: @work_item["work_type"].to_s,
          claimed_uplift_percentage: @work_item["uplift"],
          assessed_time_spent_in_minutes: 0,
          assessed_work_type: @work_item["work_type"].to_s,
          assessed_uplift_percentage: 0,
        }
      end

    private

      def total_without_uplift
        calculation[:claimed_subtotal_without_uplift]
      end

      def calculation
        @calculation ||= LaaCrimeFormsCommon::Pricing::Nsm.calculate_work_item(
          @claim.data_for_calculation,
          data_for_calculation,
        )
      rescue StandardError
        # If we don't have enough details yet to do the calculation, this will error out
        {}
      end
    end
  end
end
