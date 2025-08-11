module V1
  module PriorAuthority
    class AdditionalCost
      def initialize(_addtional_cost_record)
        @additional_cost_record = additional_cost_record
      end

      def total_cost
        if @additional_cost_record["unit_type"] == "per_item"
          total_item_cost
        else
          ((@additional_cost_record["period"] / 60.0) * @additional_cost_record["cost_per_hour"]).round(2)
        end
      end

      def total_item_cost
        @additional_cost_record["items"] * @additional_cost_record["cost_per_item"]
      end
    end
  end
end
