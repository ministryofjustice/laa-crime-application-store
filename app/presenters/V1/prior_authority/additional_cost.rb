require "bigdecimal"
require "bigdecimal/util"

module V1
  module PriorAuthority
    class AdditionalCost
      def initialize(record)
        @record = record
      end

      def total_cost
        @record["unit_type"] == "per_item" ? total_item_cost : total_time_cost
      end

      def total_item_cost
        @record["items"].to_i * @record["cost_per_item"].to_d
      end

      def total_time_cost
        ((@record["period"].to_i / 60.0) * @record["cost_per_hour"].to_d).round(2)
      end
    end
  end
end
