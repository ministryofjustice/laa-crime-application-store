class PaymentRequestIndexResource
  include Alba::Resource

  attributes :request_type,
             :submitted_at

  one :payment_request_claim do
    attributes :laa_reference, :firm_name, :client_last_name
  end
end
