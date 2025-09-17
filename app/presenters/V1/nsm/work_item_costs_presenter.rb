module V1
  module Nsm
    class WorkItemCostsPresenter
      def initialize(work_item, claim)
        @work_item = work_item
        @claim = claim
      end

      # TODO: CRM457-2747 - Make assessed costs not compulsory
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
