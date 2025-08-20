class PaymentRequestSearchResultsResource
  include Alba::Resource

  attributes :id, :request_type,
             :submitted_at
  attributes :created_at, :updated_at

  one :payment_request_claim, resource: ClaimPaymentSearchResultsResource
end

