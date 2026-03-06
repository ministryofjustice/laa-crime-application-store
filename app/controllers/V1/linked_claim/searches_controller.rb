module V1
  module LinkedClaim
    class SearchesController < ApplicationController
      def create
        render json: search_results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("PaymentRequests search query raised #{e.message}")
      end

    private

      def search_results
        ::PaymentRequests::LinkSubmissionPaymentsSearchService.call(search_params, current_client_role)
      end

      def search_params
        params.permit(
          :page,
          :per_page,
          :sort_by,
          :sort_direction,
          :claim_type,
          :request_type,
          :query,
        )
      end
    end
  end
end
