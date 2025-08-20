class ClaimPaymentSearchResultsResource
  include Alba::Resource

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :laa_reference,  :office_code,
             :client_last_name
end
