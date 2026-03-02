class PaymentRequestClaimSearchResultResource
  include Alba::Resource

  attributes :id,
             :laa_reference,
             :solicitor_office_code,
             :solicitor_firm_name,
             :defendant_last_name,
             :type,
             :ufn

  def defendant_last_name(payment_request_claim)
    payment_request_claim.client_last_name
  end
end
