class PaymentRequestClaimResource
  include Alba::Resource

  attributes :type,
             :firm_name,
             :office_code,
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
             :laa_reference,
             :ufn,
             :date_received,
             :nsm_claim_id,
             :solicitor_office_code

  attributes :created_at, :updated_at
end
