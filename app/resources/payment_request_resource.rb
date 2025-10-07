class PaymentRequestResource
  include Alba::Resource

  attributes :submitter_id, :request_type,
             :submitted_at, :date_claim_received
  attributes :profit_cost, :allowed_profit_cost,
             :travel_cost, :allowed_travel_cost,
             :waiting_cost, :allowed_waiting_cost,
             :disbursement_cost, :allowed_disbursement_cost,
             if: proc { |payment_request, _attrs| payment_request.payment_request_claim.is_a? NsmClaim }
  attributes :net_assigned_counsel_cost,
             :assigned_counsel_vat,
             :allowed_net_assigned_counsel_cost,
             :allowed_assigned_counsel_vat,
             if: proc { |payment_request, _attrs| payment_request.payment_request_claim.is_a? AssignedCounselClaim }

  attributes :created_at, :updated_at

  one :payment_request_claim, resource: lambda { |resource|
    "#{resource.class.name}Resource".constantize
  }, if: proc { params[:include_claim] }
end
