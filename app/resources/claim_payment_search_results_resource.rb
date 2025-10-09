class ClaimPaymentSearchResultsResource
  include Alba::Resource

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :id, :laa_reference, :office_code,
             :client_last_name, :firm_name
end
