module V1
  module Nsm
    class LettersAndCallsCostsPresenter
      def initialize(claim)
        @claim = claim
      end

      def letters_and_calls_for_calculation
        [letters_for_calculation, calls_for_calculation]
      end

      # TODO: CRM457-2747 - Make assessed costs not compulsory
      def calls_for_calculation
        {
          type: :calls,
          claimed_items: calls["count"].to_i,
          claimed_uplift_percentage: calls["uplift"].to_i,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        }
      end

      def letters_for_calculation
        {
          type: :letters,
          claimed_items: letters["count"].to_i,
          claimed_uplift_percentage: letters["uplift"].to_i,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        }
      end

      def letters
        @claim["letters_and_calls"].find { _1["type"] == "letters" }
      end

      def calls
        @claim["letters_and_calls"].find { _1["type"] == "calls" }
      end
    end
  end
end
