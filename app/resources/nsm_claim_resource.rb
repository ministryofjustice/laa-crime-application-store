class NsmClaimResource
  include Alba::Resource

  root_key :nsm_claim

  attribute :claim_type do |resource|
    "#{resource.class.name}"
  end

  attributes :laa_reference, :ufn, :date_received,
    :firm_name, :office_code, :stage_code,
    :client_surname, :case_concluded_date,
    :court_name, :court_attendances, :no_of_defendants,
    :created_at, :updated_at
end
