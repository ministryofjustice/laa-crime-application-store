module V1
  class SearchesController < ApplicationController
    def create
      @data = base_query
                .where(date_submitted: (submitted_from..submitted_to))
                .where(date_updated: (updated_from..updated_to))
                .where_terms(search_params[:query])

      render json: build_results(@data), status: :created
    end

  private

    def base_query
      conditions = {}
      conditions[:submission_type] = submission_type if submission_type
      conditions[:status] = status if status

      Search.where(**conditions)
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
          assigned_caseworker
          status
          risk
        ],
      )
    end
  end
end
