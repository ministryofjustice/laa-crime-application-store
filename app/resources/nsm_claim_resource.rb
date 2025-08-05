class NsmClaimResource
  include Alba::Resource

  root_key :nsm_claim

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :laa_reference, :ufn, :date_received,
             :firm_name, :office_code, :stage_code,
             :client_first_name, :client_last_name, :work_completed_date,
             :outcome_code, :matter_type, :youth_court,
             :court_name, :court_attendances, :no_of_defendants,
             :created_at, :updated_at
end
