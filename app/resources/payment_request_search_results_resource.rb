class PaymentRequestSearchResultsResource
  include Alba::Resource

  attributes :id, :request_type,
             :submitted_at, :submission_id
  attributes :created_at, :updated_at

  one :payable_claim, resource: ClaimPaymentSearchResultsResource

  def submission_id(payment_request)
    payment_request.payable_claim&.submission_id
  end
end
