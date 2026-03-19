class PayableClaimSearchResultResource
  include Alba::Resource

  attributes :id,
             :laa_reference,
             :solicitor_office_code,
             :solicitor_firm_name,
             :defendant_last_name,
             :type,
             :ufn

  def defendant_last_name(payable_claim)
    payable_claim.client_last_name
  end
end
