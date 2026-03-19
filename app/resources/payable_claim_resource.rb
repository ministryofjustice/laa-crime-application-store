class PayableClaimResource
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
             :court,
             :stage_reached,
             :hearing_outcome_code,
             :number_of_attendances,
             :number_of_defendants,
             :submission_id,
             :defendant_first_name,
             if: proc { |payable_claim| payable_claim.is_a? NsmClaim }

  attributes :counsel_office_code,
             :counsel_firm_name,
             if: proc { |payable_claim| payable_claim.is_a? AssignedCounselClaim }

  attributes :created_at, :updated_at

  many :payment_requests, resource: PaymentRequestResource
  one :nsm_claim, if: proc { |payable_claim| payable_claim.is_a? AssignedCounselClaim }
  one :assigned_counsel_claim, if: proc { |payable_claim| payable_claim.is_a? NsmClaim }

  def stage_reached(payable_claim)
    payable_claim.stage_code
  end

  def hearing_outcome_code(payable_claim)
    payable_claim.outcome_code
  end

  def number_of_attendances(payable_claim)
    payable_claim.court_attendances
  end

  def number_of_defendants(payable_claim)
    payable_claim.no_of_defendants
  end

  def court(payable_claim)
    if payable_claim.court_id == I18n.t("laa_crime_forms_common.shared.custom")
      "#{payable_claim.court_name} - #{I18n.t('laa_crime_forms_common.shared.na')}"
    else
      "#{payable_claim.court_name} - #{payable_claim.court_id}"
    end
  end

  def submission_id(payable_claim)
    payable_claim.submission_id
  end

  def defendant_first_name(payable_claim)
    payable_claim.client_first_name
  end

  def defendant_last_name(payable_claim)
    payable_claim.client_last_name
  end
end
