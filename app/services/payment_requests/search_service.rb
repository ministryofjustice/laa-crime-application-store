module PaymentRequests
  class SearchService
    SORTABLE_COLUMNS = %w[
      ufn
      laa_reference
      office_code
      client_last_name
      payable_type
      submitted_at
    ].freeze

    attr_reader :search_params

    def initialize(search_params)
      @search_params = search_params
    end

    def self.call(search_params)
      new(search_params).call
    end

    def call
      @data = search_query

      search_results
    end

  private
    # NsmClaim → Date Recieved (Date Range)
    # PaymentRequest → Submitted At (Date Range)
    # PaymentRequest → Payable Type (the class of the polymorphic associated record)
    #
    # QUERY params
    # AssignedCounselClaim → LAA Reference
    # NsmClaim → LAA Reference
    # NsmClaim → UFN
    # NsmClaim → Office Code (this should provide all payment records related to the nsm claim including it’s associated Assigned Counsel claim and their amendments)
    # NsmClaim → Defendant Surname

    def search_query
      claims = PaymentRequest.with_claims_eager_load
      claims = claims.where("payment_requests.payable_type = 'NsmClaim' AND nsm_claims.date_received BETWEEN ? AND ?",
        date_received_from, date_received_to) if (date_received_from.present? || date_received_to.present?)
      claims = claims.where(submitted_at: (submitted_from..submitted_to)) if (submitted_from.present? || submitted_to.present?)
      claims = claims.where(payable_type: payable_type) if payable_type.present?
      claims = claims.where(
        "(payment_requests.payable_type = 'AssignedCounselClaim' AND assigned_counsel_claims.laa_reference = ?) OR " \
        "(payment_requests.payable_type = 'NsmClaim' AND nsm_claims.laa_reference = ?)",
        query_params[:laa_reference], query_params[:laa_reference]
      ) if query_params[:laa_reference].present?
      claims = claims.where("payment_requests.payable_type = 'NsmClaim' AND nsm_claims.ufn = ?", query_params[:nsm_ufn]) if query_params[:nsm_ufn].present?
      claims = claims.where("payment_requests.payable_type = 'NsmClaim' AND nsm_claims.office_code = ?", query_params[:nsm_office_code]) if query_params[:nsm_office_code].present?
      debugger
      claims = claims.where("payment_requests.payable_type = 'NsmClaim' AND nsm_claims.client_last_name = ?", query_params[:nsm_client_last_name]) if query_params[:nsm_client_last_name].present?
      claims = claims.order(sort_clause)
      claims
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

      NsmClaim.find(ids)
                .sort_by { ids.index(_1.id) }
                .map { _1.as_json(client_role:) }
    end

    def submitted_from
      search_params[:submitted_from]&.to_date&.beginning_of_day
    end

    def submitted_to
      search_params[:submitted_to]&.to_date&.end_of_day
    end

    def date_received_from
      search_params[:date_received_from]&.to_date&.beginning_of_day
    end

    def date_received_to
      search_params[:date_received_to]&.to_date&.end_of_day
    end

    def payable_type
      search_params[:payable_type]
    end

    def query_params
      return if query.blank?

      words = query.strip.downcase.split(/\s+/)

      @query_params ||= words.each_with_object({}) do |word, acc|
        if word.start_with?('laa-')
          acc[:laa_reference] = word
        elsif word.match?(/^\d+\/\d+$/)
          acc[:nsm_ufn] = word
        elsif word.match?(/^\d.*[a-zA-Z]$/)
          acc[:nsm_office_code] = word
        else
          acc[:nsm_client_last_name] = word
        end
      end
    end

    def sort_clause
      return "submitted_at desc" unless search_params[:sort_by]
      raise "Unsortable column \"#{sort_by}\" supplied as sort_by argument" unless SORTABLE_COLUMNS.include?(sort_by.downcase)

      if sort_by.in?(%w[submitted_at])
        "#{sort_by} #{sort_direction}"
      else
        "LOWER(#{sort_by}) #{sort_direction}"
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

    private

    def query
      search_params.fetch(:query, nil)
    end
  end
end
