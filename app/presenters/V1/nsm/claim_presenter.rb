module V1
  module Nsm
    class ClaimPresenter < V1::Base
      def main_defendant
        @application["defendants"].find { _1["main"] }
      end

      def totals
        @totals ||= LaaCrimeFormsCommon::Pricing::Nsm.totals(full_data_for_calculation)
      end

      def work_items_for_calculation
        @application["work_items"].map { WorkItemCosts.new(_1, @application).data_for_calculation }
      end

      def disbursements_for_calculation
        @application["disbursements"].map { DisbursementCosts.new(_1).data_for_calculation }
      end

      def letters_and_calls_for_calculation
        LettersAndCallsCosts.new(@application).letters_and_calls_for_calculation
      end

      # TODO: The classes used for this method only account for claimed costs - need to add assessed costs in also
      def full_data_for_calculation
        data_for_calculation.merge(
          work_items: work_items_for_calculation,
          disbursements: disbursements_for_calculation,
          letters_and_calls: letters_and_calls_for_calculation,
        )
      end

      def data_for_calculation
        {
          claim_type: @application["claim_type"],
          rep_order_date: @application["rep_order_date"],
          cntp_date: @application["cntp_date"],
          claimed_youth_court_fee_included: @application.fetch("include_youth_court_fee",  false),
          assessed_youth_court_fee_included: @application.fetch("allowed_youth_court_fee", false),
          youth_court: @application["youth_court"] == "yes",
          plea_category: @application["plea_category"],
          vat_registered: @application.dig("firm_office", "vat_registered") == "yes",
          work_items: [],
          letters_and_calls: [],
          disbursements: [],
        }
      end
    end
  end
end
