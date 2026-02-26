class Crm7SearchResultsResource
  include Alba::Resource

  attributes :id, :request_type,
             :submitted_at, :submission_id
  attributes :created_at, :updated_at

  one :payment_request_claim, resource: ClaimPaymentSearchResultsResource
end
