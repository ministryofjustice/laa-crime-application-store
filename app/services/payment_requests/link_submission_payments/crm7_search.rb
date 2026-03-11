module PaymentRequests
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
        return if claim_type_excluded?

        crm7_search_results
      end

    private

      def claim_type_excluded?
        %w[assigned_counsel_appeal assigned_counsel_amendment].include?(search_params[:claim_type])
      end

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

        filtered_params[:status_with_assignment] = %w[part_grant granted]
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
