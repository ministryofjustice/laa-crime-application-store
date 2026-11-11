class PayableClaimSearchResultResource
  include Alba::Resource

  attributes :id,
             :laa_reference,
             :solicitor_office_code,
             :solicitor_firm_name,
             :defendant_name,
             :type,
             :ufn

  def defendant_name(payable_claim)
    "#{payable_claim.client_first_name} #{payable_claim.client_last_name}"
  end
end
