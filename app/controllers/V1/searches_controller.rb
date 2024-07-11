module V1
  class SearchesController < ApplicationController
    def create
      data = search_query
      raw_data = Submission.where(id: data.pluck(:id))

      render json: build_results(data, raw_data), status: :created
    rescue StandardError => e
      render json: { message: "AppStore search query raised #{e.message}" }, status: :unprocessable_entity
    end

  private

    def search_query
      relation = Search.where(date_submitted: (submitted_from..submitted_to))
      relation = relation.where(date_updated: (updated_from..updated_to))
      relation = relation.where(submission_type:) if submission_type
      relation = relation.where(status:) if status
      relation = relation.where("has_been_assigned_to ? :caseworker_id", caseworker_id:) if caseworker_id
      relation = relation.order(**sort_clause)

      relation.where_terms(query)
    end

    def build_results(data, raw_data)
      {
        metadata: {
          total_results: data.size,
          page: offset,
          per_page: limit,
        },
        data: data.limit(limit).offset(offset),
        raw_data: raw_data.limit(limit).offset(offset),
      }.to_json
    end

    def submission_type
      search_params[:submission_type]
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

    def status
      search_params[:status]
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

    def limit
      search_params.fetch(:per_page, 20).to_i
    end

    def offset
      search_params.fetch(:page, 0).to_i
    end

    def search_params
      params.permit(
        :query,
        :page,
        :per_page,
        :sort_by,
        :sort_direction,
        :submission_type,
        :submitted_from,
        :submitted_to,
        :updated_from,
        :updated_to,
        :caseworker_id,
        :status,
      )
    end
  end
end
