module Submissions
  class SearchService < BaseSearchService
    SORTABLE_COLUMNS = %w[
      ufn
      laa_reference
      firm_name
      client_name
      last_updated
      status_with_assignment
      risk_level
      service_name
      account_number
      last_state_change
    ].freeze

  private

    def search_query
      relation = Search.where(date_submitted: (submitted_from..submitted_to))
      relation = relation.where(last_updated: (updated_from..updated_to))
      relation = relation.where(application_type:) if application_type
      relation = relation.where(status_with_assignment:) if status_with_assignment
      relation = has_been_assigned_to(relation) if caseworker_id
      relation = relation.where(assigned_user_id:) if assigned_user_id
      relation = relation.where(account_number:) if account_number
      relation = relation.where(high_value:) unless high_value.nil?
      relation = relation.where.not(id: id_to_exclude) if id_to_exclude
      relation = relation.order(sort_clause)

      relation.where_terms(query)
    end

    def search_results
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

      Submission.find(ids)
                .sort_by { ids.index(_1.id) }
                .map { _1.as_json(client_role:) }
    end

    def application_type
      search_params[:application_type]
    end

    def submitted_from
      search_params[:submitted_from]&.to_date&.beginning_of_day
    end

    def submitted_to
      search_params[:submitted_to]&.to_date&.end_of_day
    end

    def updated_from
      search_params[:updated_from]&.to_date&.beginning_of_day
    end

    def updated_to
      search_params[:updated_to]&.to_date&.end_of_day
    end

    def status_with_assignment
      search_params[:status_with_assignment]
    end

    def caseworker_id
      search_params[:caseworker_id]
    end

    def assigned_user_id
      search_params[:current_caseworker_id]
    end

    def account_number
      search_params[:account_number]
    end

    def id_to_exclude
      search_params[:id_to_exclude]
    end

    def query
      search_params[:query]
    end

    def high_value
      search_params[:high_value]
    end

    def sort_clause
      return "last_updated desc" unless search_params[:sort_by]
      raise "Unsortable column \"#{sort_by}\" supplied as sort_by argument" unless SORTABLE_COLUMNS.include?(sort_by.downcase)

      if sort_by.in?(%w[last_updated risk_level last_state_change])
        "#{sort_by} #{sort_direction}"
      else
        "LOWER(#{sort_by}) #{sort_direction}"
      end
    end

    def sort_by
      search_params.fetch(:sort_by, "last_updated")
    end

    def sort_direction
      @sort_direction ||= search_params
                            .fetch(:sort_direction, "asc")
                            .downcase
                            .gsub("ascending", "asc")
                            .gsub("descending", "desc")
    end

    def has_been_assigned_to(relation)
      relation.where("assigned_user_id = :caseworker_id OR :caseworker_id = ANY(unassigned_user_ids)", caseworker_id:)
    end
  end
end
