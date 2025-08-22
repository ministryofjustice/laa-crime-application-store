require "bigdecimal"
require "bigdecimal/util"

module V1
  module PriorAuthority
    class QuoteCostsPresenter
      def initialize(quote, application)
        @quote = quote
        @application = application
      end

      def total_cost
        base_cost + travel_cost + additional_cost_value
      end

      def base_cost
        @quote["cost_type"] == "per_item" ? item_cost : time_cost
      end

      def item_cost
        @quote["cost_per_item"].to_d * @quote["items"].to_i * @quote["cost_multiplier"].to_d
      end

      def time_cost
        (@quote["cost_per_hour"].to_d * @quote["period"].to_i / 60).round(2)
      end

      def travel_cost
        (travel_cost_per_hour * travel_time / 60).round(2)
      end

      def additional_cost_value
        @application["additional_costs"].map { AdditionalCostPresenter.new(_1) }.sum(&:total_cost) || BigDecimal(0)
      end

      def primary
        @quote["primary"]
      end

    private

      def travel_cost_per_hour
        @quote["travel_cost_per_hour"]&.to_d || BigDecimal(0)
      end

      def travel_time
        @quote["travel_time"]&.to_i || BigDecimal(0)
      end
    end
  end
end
