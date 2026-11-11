class ClaimPaymentSearchResultsResource
  include Alba::Resource

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :id, :laa_reference, :solicitor_office_code,
             :client_name, :solicitor_firm_name, :ufn

  def client_name(resource)
    "#{resource.client_first_name} #{resource.client_last_name}"
  end
end
