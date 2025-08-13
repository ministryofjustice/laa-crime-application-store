module V1
  module PaymentRequests
    class SearchesController < ApplicationController
      def create
        @results = ::PaymentRequests::SearchService.call(search_params)

        render json: @results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("PaymentRequests search query raised #{e.message}")
        render json: { message: "PaymentRequests search query raised #{e.message}" }, status: :unprocessable_entity
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
          :date_received_from,
          :date_received_to,
          :payable_type,
          :query
        )
      end
    end
  end
end
