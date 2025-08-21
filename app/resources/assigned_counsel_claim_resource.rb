class AssignedCounselClaimResource
  include Alba::Resource

  root_key :assigned_counsel_claim

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :laa_reference,
             :office_code, :nsm_claim_id,
             :date_received, :ufn,
             :solicitor_office_code,
             :client_last_name,
             :created_at, :updated_at
end
