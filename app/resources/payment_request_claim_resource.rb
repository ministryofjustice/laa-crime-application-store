class PaymentRequestClaimResource
  include Alba::Resource

  attributes :id,
             :type,
             :laa_reference,
             :date_received,
             :office_code

  attributes :firm_name,
             :stage_code,
             :work_completed_date,
             :court_name,
             :court_attendances,
             :no_of_defendants,
             :client_first_name,
             :client_last_name,
             :outcome_code,
             :matter_type,
             :youth_court,
             :ufn,
             if: proc { |payment_request_claim| payment_request_claim.is_a? NsmClaim }

  attributes :solicitor_office_code,
             :nsm_claim_id,
             if: proc { |payment_request_claim| payment_request_claim.is_a? AssignedCounselClaim }

  attribute :submission_id do |payment_request_claim|
    payment_request_claim.submission&.id
  end

  attributes :created_at, :updated_at

  many :payment_requests, resource: PaymentRequestResource
end
