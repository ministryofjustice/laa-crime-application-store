SELECT
  payable_claims.id AS claim_id,
  payable_claims.court_attendances AS court_attendances,
  payable_claims.court_name AS court_name,
  payable_claims.court_id AS court_id,
  payable_claims.matter_type AS matter_type,
  payable_claims.no_of_defendants AS no_of_defendants,
  payable_claims.outcome_code AS outcome_code,
  payable_claims.solicitor_firm_name AS office_name,
  payable_claims.solicitor_office_code AS office_code,
  payable_claims.stage_code AS stage_code,
  payable_claims.ufn AS ufn,
  payable_claims.work_completed_date AS work_completed_date,
  payable_claims.youth_court AS youth_court,
  payment_requests.request_type AS request_type,
  payment_requests.allowed_disbursement_cost AS allowed_disbursement_cost,
  payment_requests.claimed_disbursement_cost AS claimed_disbursement_cost,
  payment_requests.allowed_profit_cost AS allowed_profit_cost,
  payment_requests.claimed_profit_cost AS claimed_profit_cost,
  payment_requests.allowed_travel_cost AS allowed_travel_cost,
  payment_requests.claimed_travel_cost AS claimed_travel_cost,
  payment_requests.allowed_waiting_cost AS allowed_waiting_cost,
  payment_requests.claimed_waiting_cost AS claimed_waiting_cost,
  payment_requests.claimed_total AS claimed_total,
  payment_requests.allowed_total AS allowed_total,
  payment_requests.date_received AS date_received,
  payment_requests.submitted_at AS submitted_at
FROM
  payment_requests
  INNER JOIN payable_claims ON payment_requests.payable_claim_id = payable_claims.id
WHERE
  payment_requests.request_type IN (
    'breach_of_injunction',
    'non_standard_magistrate',
    'non_standard_mag_supplemental',
    'non_standard_mag_appeal',
    'non_standard_mag_amendment'
  )