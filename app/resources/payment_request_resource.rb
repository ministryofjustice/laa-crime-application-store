class PaymentRequestResource
  include Alba::Resource

  root_key :payment_request

  attributes :submitter_id, :request_type,
  :profit_cost, :allowed_profit_cost,
  :travel_cost, :allowed_travel_cost,
  :waiting_cost, :allowed_waiting_cost,
  :disbursement_cost, :allowed_disbursement_cost,
  :submitted_at, :date_claim_received,
  :net_assigned_counsel_cost, :assigned_counsel_vat,
  :allowed_assigned_counsel_vat,
  :created_at, :updated_at,

  attribute :allowed_assigned_counsel_cost do |resource|
    resource.allowed_net_assigned_counsel_cost
  end

  one :payable, resource: ->(resource) do
    "#{resource.class.name}Resource".constantize
  end
end
