class PaymentRequestClaimResource
  include Alba::Resource

  attributes :id,
             :type,
             :laa_reference,
             :solicitor_office_code,
             :solicitor_firm_name,
             :defendant_last_name,
             :ufn

  attributes :work_completed_date,
             :matter_type,
             :youth_court,
             :stage_reached,
             :hearing_outcome_code,
             :number_of_attendances,
             :number_of_defendants,
             :court,
             :submission_id,
             :defendant_first_name,
             if: proc { |payment_request_claim| payment_request_claim.is_a? NsmClaim }

  attributes :counsel_office_code,
             :counsel_firm_name,
             if: proc { |payment_request_claim| payment_request_claim.is_a? AssignedCounselClaim }

  attributes :created_at, :updated_at

  many :payment_requests, resource: PaymentRequestResource
  one :nsm_claim, if: proc { |payment_request_claim| payment_request_claim.is_a? AssignedCounselClaim }
  one :assigned_counsel_claim, if: proc { |payment_request_claim| payment_request_claim.is_a? NsmClaim }

  def stage_reached(payment_request_claim)
    payment_request_claim.stage_code
  end

  def hearing_outcome_code(payment_request_claim)
    payment_request_claim.outcome_code
  end

  def number_of_attendances(payment_request_claim)
    payment_request_claim.court_attendances
  end

  def number_of_defendants(payment_request_claim)
    payment_request_claim.no_of_defendants
  end

  def court(payment_request_claim)
    payment_request_claim.court_name
  end

  def submission_id(payment_request_claim)
    payment_request_claim.submission_id || payment_request_claim.submission&.id
  end

  def defendant_first_name(payment_request_claim)
    payment_request_claim.client_first_name
  end

  def defendant_last_name(payment_request_claim)
    payment_request_claim.client_last_name
  end
end
