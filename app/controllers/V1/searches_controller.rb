module V1
  class SearchesController < ApplicationController
    def create
      render json: build_results(search_query), status: :created
    end

  private

    def search_query
      relation = Search.where(date_submitted: (submitted_from..submitted_to))
      relation = relation.where(date_updated: (updated_from..updated_to))
      relation = relation.where(submission_type:) if submission_type
      relation = relation.where(status:) if status
      relation = relation.where("has_been_assigned_to ? :caseworker_id", caseworker_id:) if caseworker_id

      relation.where_terms(query)
    end

    def build_results(data)
      {
        metadata: {
          total_results: data.size,
          page: offset,
          per_page: limit,
        },
        data: data.limit(limit).offset(offset),
      }.to_json
    end

    def submission_type
      filters[:submission_type]
    end

    def submitted_from
      filters[:submitted_from]&.to_date
    end

    def submitted_to
      filters[:submitted_to]&.to_date
    end

    def updated_from
      filters[:updated_from]&.to_date
    end

    def updated_to
      filters[:updated_to]&.to_date
    end

    def status
      filters[:status]
    end

    def caseworker_id
      filters[:caseworker_id]
    end

    def query
      search_params[:query]
    end

    def limit
      search_params.fetch(:per_page, 20).to_i
    end

    def offset
      search_params.fetch(:page, 0).to_i
    end

    def filters
      search_params[:filters]
    end

    def search_params
      params.permit(
        :query,
        :page,
        :per_page,
        :sort_by,
        :sort_direction,
        filters: %i[
          submission_type
          submitted_from
          submitted_to
          updated_from
          updated_to
          caseworker_id
          status
        ],
      )
    end
  end
end
