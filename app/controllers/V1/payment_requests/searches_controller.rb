module V1
  module PaymentRequests
    class SearchesController < ApplicationController
      def create
        search_results = ::PaymentRequests::SearchService.call(search_params, current_client_role)
        render json: search_results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("PaymentRequests search query raised #{e.message}")
        render json: { message: "PaymentRequests search query raised #{e.message}" }, status: :unprocessable_content
      end

    private

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
