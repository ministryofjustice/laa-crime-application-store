class PaymentRequestResource
  include Alba::Resource

  attributes :id, :submitter_id, :request_type,
             :submitted_at, :date_received
  attributes :claimed_profit_cost, :allowed_profit_cost,
             :claimed_travel_cost, :allowed_travel_cost,
             :claimed_waiting_cost, :allowed_waiting_cost,
             :claimed_disbursement_cost, :allowed_disbursement_cost,
             if: proc { |payment_request, _attrs| payment_request.payment_request_claim.is_a? NsmClaim }
  attributes :claimed_net_assigned_counsel_cost,
             :claimed_assigned_counsel_vat,
             :allowed_net_assigned_counsel_cost,
             :allowed_assigned_counsel_vat,
             if: proc { |payment_request, _attrs| payment_request.payment_request_claim.is_a? AssignedCounselClaim }

  attributes :claimed_total, :allowed_total,
             if: proc { |pr, _|
               [NsmClaim, AssignedCounselClaim].any? { pr.payment_request_claim.is_a?(_1) }
             }

  attributes :created_at, :updated_at

  one :payment_request_claim, resource: lambda { |resource|
    "#{resource.class.name}Resource".constantize
  }, if: proc { params[:include_claim] }
end
