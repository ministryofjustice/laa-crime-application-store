module V1
  module PriorAuthority
    class Quote
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
        @quote["cost_per_item"] * @quote["items"] * @quote["cost_multiplier"]
      end

      def time_cost
        (@quote["cost_per_hour"] * @quote["period"] / 60).round(2)
      end

      def travel_cost
        (@quote["travel_cost_per_hour"] * @quote["travel_time"] / 60).round(2)
      end

      def additional_cost_value
        @application["additional_costs"].map { AdditionalCost.new(_1) }.sum(&:total_cost)
      end

      def primary
        @quote["primary"]
      end
    end
  end
end
