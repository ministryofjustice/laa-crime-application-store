SELECT
  payment_requests.id AS payment_request_id,
  payable_claims.id AS claim_id,
  payable_claims.laa_reference AS laa_reference,
  CASE payment_requests.request_type
    WHEN 'assigned_counsel' THEN 'AC'
    WHEN 'assigned_counsel_appeal' THEN 'AC Appeal'
    WHEN 'assigned_counsel_amendment' THEN 'AC Amendment'
  END AS payment_type,
  'CRM8' AS description,
  'CL_CON_CWA' AS invoice_type,
  NULLIF(
    TRIM(CONCAT_WS(' ', payable_claims.client_first_name, payable_claims.client_last_name)),
    ''
  ) AS client_name,
  payable_claims.ufn AS case_reference,
  payment_requests.submitted_at::date AS date_requested,
  payable_claims.counsel_office_code AS office_code,
  COALESCE(
    payment_requests.allowed_total,
    COALESCE(payment_requests.allowed_net_assigned_counsel_cost, 0) +
      COALESCE(payment_requests.allowed_assigned_counsel_vat, 0)
  ) AS invoice_amount_inc_vat,
  CASE
    WHEN COALESCE(payment_requests.allowed_assigned_counsel_vat, payment_requests.claimed_assigned_counsel_vat, 0) = 0 THEN 0
    ELSE 20
  END AS tax_amount_percentage,
  'Profit costs' AS fee_type,
  payable_claims.counsel_firm_name AS provider_reference,
  payment_requests.request_type AS request_type,
  payment_requests.claimed_net_assigned_counsel_cost AS claimed_net_assigned_counsel_cost,
  payment_requests.claimed_assigned_counsel_vat AS claimed_assigned_counsel_vat,
  payment_requests.claimed_total AS claimed_total,
  payment_requests.allowed_net_assigned_counsel_cost AS allowed_net_assigned_counsel_cost,
  payment_requests.allowed_assigned_counsel_vat AS allowed_assigned_counsel_vat,
  payment_requests.allowed_total AS allowed_total,
  payment_requests.date_claim_assessed AS date_claim_assessed,
  payment_requests.submitted_at AS submitted_at
FROM
  payment_requests
  INNER JOIN payable_claims ON payment_requests.payable_claim_id = payable_claims.id
WHERE
  payment_requests.request_type IN (
    'assigned_counsel',
    'assigned_counsel_appeal',
    'assigned_counsel_amendment'
  )
