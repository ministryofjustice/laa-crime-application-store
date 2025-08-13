module V1
  module Nsm
    class WorkItemCosts
      def initialize(work_item, claim)
        @work_item = work_item
        @claim = claim
      end

      def total_cost
        calculation[:claimed_total_exc_vat]
      end

      def allowed_total_cost
        calculation[:assessed_total_exc_vat]
      end

      def data_for_calculation
        {
          claimed_time_spent_in_minutes: @work_item["time_spent"].to_i,
          claimed_work_type: @work_item["work_type"].to_s,
          claimed_uplift_percentage: @work_item["uplift"],
          assessed_time_spent_in_minutes: 0,
          assessed_work_type: @work_item["work_type"].to_s,
          assessed_uplift_percentage: 0,
        }
      end
    end
  end
end
