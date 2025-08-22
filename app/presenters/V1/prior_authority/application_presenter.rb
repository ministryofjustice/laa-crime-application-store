module V1
  module PriorAuthority
    class ApplicationPresenter < V1::Base
      def primary_quote
        @primary_quote ||= quote_costs.detect(&:primary)
      end

      def quote_costs
        @quotes = @application["quotes"].map { QuoteCosts.new(_1, @application) }
      end

      def defendant_full_name
        [
          @application["defendant"]["first_name"],
          @application["defendant"]["last_name"],
        ].join(" ")
      end
    end
  end
end
