module V1
  module LinkedClaim
    class SearchesController < ApplicationController
      def create
        render json: search_results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("PaymentRequests search query raised #{e.message}")
        render json: { message: "PaymentRequests search query raised #{e.message}" }, status: :unprocessable_content
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
          :submitted_from,
          :submitted_to,
          :received_from,
          :received_to,
          :request_type,
          :submission_id,
          :query,
        )
      end
    end
  end
end
