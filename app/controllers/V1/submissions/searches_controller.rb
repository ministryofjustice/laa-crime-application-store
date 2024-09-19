module V1
  module Submissions
    class SearchesController < ApplicationController
      def create
        @results = ::Submissions::SearchService.call(search_params)

        render json: @results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("AppStore search query raised #{e.message}")
        render json: { message: "AppStore search query raised #{e.message}" }, status: :unprocessable_entity
      end

    private

      def search_params
        params.permit(
          :query,
          :page,
          :per_page,
          :sort_by,
          :sort_direction,
          :application_type,
          :submitted_from,
          :submitted_to,
          :updated_from,
          :updated_to,
          :risk,
          :caseworker_id,
          :status_with_assignment,
        )
      end
    end
  end
end
