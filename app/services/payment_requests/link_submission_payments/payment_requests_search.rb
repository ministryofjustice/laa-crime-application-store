module PaymentRequests
  module LinkSubmissionPayments
    class PaymentRequestsSearch < SearchService
      include ClaimTypeGroupHelper

      SORTABLE_COLUMNS = %w[
        ufn
        laa_reference
        solicitor_office_code
        client_last_name
        request_type
        solicitor_firm_name
        created_at
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
        claims = claim_type.all
        claims = claims.where("LOWER(payment_request_claims.laa_reference) = ?", query_params[:laa_reference].downcase) if query_params[:laa_reference].present?
        claims = claims.where(ufn: query_params[:ufn]) if query_params[:ufn].present?
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
          data: serialized_data,
        }.to_json
      end

      def sort_clause
        return "created_at desc" unless search_params[:sort_by]
        raise "Unsortable column \"#{sort_by}\" supplied as sort_by argument" unless SORTABLE_COLUMNS.include?(sort_by.downcase)

        if sort_by.in?(%w[created_at request_type])
          "#{sort_by} #{sort_direction}"
        else
          "LOWER(payment_request_claims.#{sort_by}) #{sort_direction}"
        end
      end

      def serialized_data
        PaymentRequestClaimSearchResultResource.new(@data.limit(limit).offset(offset))
      end

      def claim_type
        find_claim_type_group(search_params[:request_type]).constantize
      end

      def query
        search_params.fetch(:query, nil)
      end
    end
  end
end
