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
      memoized_search(LinkSubmissionPayments::Crm7Search)
    end

    def memoized_search(klass)
      @searches ||= {}
      @searches[klass] ||= klass.new(search_params, client_role)
    end
  end
end
