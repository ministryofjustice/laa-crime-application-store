module PaymentRequests
  class LinkSubmissionPaymentsSearchService < BaseSearchService
    def call
      payment_results = payment_requests_search.call
      return payment_results if payment_requests_search.results?

      crm7_search.call || payment_results
    end

  private

    def payment_requests_search
      memoized_search(LinkSubmissionPayments::PaymentRequestsSearch)
    end

    def crm7_search
      memoized_search(::Submissions::LinkSubmissionPayments::Crm7Search)
    end

    def memoized_search(klass)
      @searches ||= {}
      @searches[klass] ||= klass.new(search_params, client_role)
    end
  end

  module LinkSubmissionPayments
    class PaymentRequestsSearch < BaseSearchService
      SORTABLE_COLUMNS = %w[
        ufn
        laa_reference
        solicitor_office_code
        client_last_name
        request_type
        submitted_at
        solicitor_firm_name
      ].freeze

      def call
        @data = search_query
        @has_results = @data.exists?
        search_results
      end

      def results?
        @has_results || false
      end

    private

      def search_query
        claims = PaymentRequest
                 .left_outer_joins(:payment_request_claim)
                 .includes(:payment_request_claim)
        claims = claims.where("LOWER(payment_request_claims.laa_reference) = ?", query_params[:laa_reference].downcase) if query_params[:laa_reference].present?
        claims = claims.where(payment_request_claims: { ufn: query_params[:ufn] }) if query_params[:ufn].present?
        claims = claims.where("LOWER(payment_request_claims.solicitor_office_code) = ?", query_params[:office_code].downcase) if query_params[:office_code].present?
        claims = claims.where("LOWER(payment_request_claims.client_last_name) % ?::text", "%#{query_params[:client_last_name].downcase}%") if query_params[:client_last_name].present?
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

        if sort_by.in?(%w[submitted_at request_type])
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
end

module Submissions
  module LinkSubmissionPayments
    class Crm7Search < BaseSearchService
      SUBMISSION_SEARCH_KEYS = %i[
        query
        sort_by
        sort_direction
        page
        per_page
        application_type
      ].freeze

      def call
        crm7_search_results
      end

    private

      def crm7_search_results
        response = submissions_search_response
        return unless response

        results = response.fetch(:raw_data, []).map { Crm7SearchResult.new(_1) }
        return if results.empty?

        {
          metadata: response.fetch(:metadata),
          data: Crm7SearchResultsResource.new(results),
        }.to_json
      end

      def submissions_search_response
        parsed = JSON.parse(submissions_search_service.call).deep_symbolize_keys
        metadata = parsed.fetch(:metadata, {})
        return if metadata.fetch(:total_results, 0).to_i.zero?

        metadata[:page] ||= page
        metadata[:per_page] ||= per_page

        {
          metadata: metadata.slice(:total_results, :page, :per_page),
          raw_data: parsed.fetch(:raw_data, []),
        }
      end

      def submissions_search_service
        @submissions_search_service ||= ::Submissions::SearchService.new(crm7_search_params, client_role)
      end

      def crm7_search_params
        params = search_params.to_h.deep_symbolize_keys
        filtered_params = params.slice(*SUBMISSION_SEARCH_KEYS)
        filtered_params.delete(:sort_by)
        filtered_params[:application_type] = "crm7"
        filtered_params[:query] ||= query
        filtered_params[:page] ||= page
        filtered_params[:per_page] ||= per_page
        filtered_params
      end

      def query
        search_params.fetch(:query, nil)
      end
    end
  end
end
