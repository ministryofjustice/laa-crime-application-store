module V1
  module Submissions
    class SearchesController < ApplicationController
      def create
        @data = search_query

        render json: build_results, status: :created
      rescue StandardError => e
        Rails.logger.fatal("AppStore search query raised #{e.message}")
        render json: { message: "AppStore search query raised #{e.message}" }, status: :unprocessable_entity
      end

    private

      def search_query
        relation = Search.where(date_submitted: (submitted_from..submitted_to))
        relation = relation.where(date_updated: (updated_from..updated_to))
        relation = relation.where(application_type:) if application_type
        relation = relation.where(status_with_assignment:) if status_with_assignment
        relation = relation.where("has_been_assigned_to ? :caseworker_id", caseworker_id:) if caseworker_id
        relation = relation.order(**sort_clause)

        relation.where_terms(query)
      end

      def build_results
        {
          metadata: {
            total_results: @data.size,
            page:,
            per_page:,
          },
          data: @data.limit(limit).offset(offset),
          raw_data: raw_data_for_page,
        }.to_json
      end

      def raw_data_for_page
        # Ensures sorting and paginating works for the raw_data query.
        # Paginate (offset/limit) here just to get an array of ordered ids for
        # the page then query the "raw data" for just those ids, sorting by the
        # order they were in from the "data".
        ids = @data.limit(limit).offset(offset).pluck(:id)

        Submission.find(ids).sort_by do |submission|
          ids.index(submission.id)
        end
      end

      def application_type
        search_params[:application_type]
      end

      def submitted_from
        search_params[:submitted_from]&.to_date
      end

      def submitted_to
        search_params[:submitted_to]&.to_date
      end

      def updated_from
        search_params[:updated_from]&.to_date
      end

      def updated_to
        search_params[:updated_to]&.to_date
      end

      def status_with_assignment
        search_params[:status_with_assignment]
      end

      def caseworker_id
        search_params[:caseworker_id]
      end

      def query
        search_params[:query]
      end

      def sort_clause
        return { date_updated: :desc } unless search_params[:sort_by]

        { sort_by => sort_direction }
      end

      def sort_by
        search_params.fetch(:sort_by, :date_updated)
      end

      def sort_direction
        @sort_direction ||= search_params
                              .fetch(:sort_direction, "asc")
                              .downcase
                              .gsub("ascending", "asc")
                              .gsub("descending", "desc")
      end

      # page 1: (1-1) * 10 = 0 (rows 1 to 10) - offset should be 0
      # page 2: (2-1) * 10 = 10 (rows 11 to 20) - offset should be 10
      # ...
      def offset
        (page - 1) * limit
      end

      def limit
        per_page
      end

      def per_page
        search_params.fetch(:per_page, 10).to_i
      end

      def page
        search_params.fetch(:page, 1).to_i
      end

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
          :caseworker_id,
          :status_with_assignment,
        )
      end
    end
  end
end
