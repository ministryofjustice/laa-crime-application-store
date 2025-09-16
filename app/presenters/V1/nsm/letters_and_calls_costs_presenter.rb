module V1
  module Nsm
    class LettersAndCallsCostsPresenter
      def initialize(claim)
        @claim = claim
      end

      def letters_and_calls_for_calculation
        [letters_for_calculation, calls_for_calculation]
      end

       # TODO: Add real assessed costs if using caseworker assessed data
      def calls_for_calculation
        {
          type: :calls,
          claimed_items: @claim["calls"].to_i,
          claimed_uplift_percentage: @claim["calls_uplift"].to_i,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        }
      end

      def letters_for_calculation
        {
          type: :letters,
          claimed_items: @claim["letters"],
          claimed_uplift_percentage: @claim["letters_uplift"].to_i,
          assessed_items: 0,
          assessed_uplift_percentage: 0,
        }
      end
    end
  end
end
