class NsmClaimResource
  include Alba::Resource

  root_key :nsm_claim

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :laa_reference, :ufn, :date_received,
             :solicitor_firm_name, :solicitor_office_code, :stage_code,
             :client_first_name, :client_last_name, :work_completed_date,
             :outcome_code, :matter_type, :youth_court,
             :court_name, :court_attendances, :no_of_defendants,
             :created_at, :updated_at

  many :payment_requests, params: { include_claim: false }
end
