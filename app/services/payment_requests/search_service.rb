module PaymentRequests
  class SearchService < BaseSearchService
    SORTABLE_COLUMNS = %w[
      ufn
      laa_reference
      office_code
      client_last_name
      claim_type
      submitted_at
    ].freeze

  private

    def search_query
      claims = PaymentRequest
        .left_outer_joins(:payment_request_claim)
        .includes(:payment_request_claim)
      claims = claims.where(payment_request_claims: { date_received: received_from..received_to }) if date_received?
      claims = claims.where(submitted_at: (submitted_from..submitted_to)) if submitted_date?
      claims = claims.where(payment_request_claims: { type: claim_type }) if claim_type.present?
      claims = claims.where("LOWER(payment_request_claims.laa_reference) = ?", query_params[:laa_reference].downcase) if query_params[:laa_reference].present?
      claims = claims.where(payment_request_claims: { ufn: query_params[:ufn] }) if query_params[:ufn].present?
      claims = claims.where("LOWER(payment_request_claims.office_code) = ?", query_params[:office_code].downcase) if query_params[:office_code].present?
      claims = claims.where("payment_request_claims.client_last_name ILIKE ?", query_params[:client_last_name].downcase) if query_params[:client_last_name].present?
      claims.order(sort_clause)
    end

    def search_results
      {
        metadata: {
          total_results: @data.size,
          page:,
          per_page:,
        },
        data: serialialized_data,
      }.to_json
    end

    def submitted_from
      search_params[:submitted_from]&.to_date&.beginning_of_day
    end

    def submitted_to
      search_params[:submitted_to]&.to_date&.end_of_day
    end

    def received_from
      search_params[:received_from]&.to_date&.beginning_of_day
    end

    def received_to
      search_params[:received_to]&.to_date&.end_of_day
    end

    def date_received?
      received_from.present? || received_to.present?
    end

    def submitted_date?
      submitted_from.present? || submitted_to.present?
    end

    def claim_type
      search_params[:claim_type]
    end

    def query_params
      return {} if query.nil?

      words = query.strip.downcase.split(/\s+/)
      results = words.each_with_object({}) do |word, acc|
        if word.start_with?("laa-")
          acc[:laa_reference] = word
        elsif /^\d{6}|\d{6}\/\d{3}$/.match?(word)
          acc[:ufn] = word
        elsif /^\d.*[a-zA-Z]$/.match?(word)
          acc[:office_code] = word
        else
          acc[:client_last_name] = word
        end
      end
      @query_params ||= results
    end

    def sort_clause
      return "submitted_at desc" unless search_params[:sort_by]
      raise "Unsortable column \"#{sort_by}\" supplied as sort_by argument" unless SORTABLE_COLUMNS.include?(sort_by.downcase)

      if sort_by.in?(%w[submitted_at])
        "#{sort_by} #{sort_direction}"
      else
        "LOWER(payment_request_claims.#{sort_by}) #{sort_direction}"
      end
    end

    def sort_by
      search_params.fetch(:sort_by, "submitted_at")
    end

    def sort_direction
      @sort_direction ||= search_params
                            .fetch(:sort_direction, "asc")
                            .downcase
                            .gsub("ascending", "asc")
                            .gsub("descending", "desc")
    end

    def serialialized_data
      PaymentRequestSearchResultsResource.new(@data.limit(limit).offset(offset))
    end

    def query
      search_params.fetch(:query, nil)
    end
  end
end
