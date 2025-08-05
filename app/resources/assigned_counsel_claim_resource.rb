class AssignedCounselClaimResource
  include Alba::Resource

  root_key :assigned_counsel_claim

  attribute :claim_type do |resource|
    "#{resource.class.name}"
  end

  attributes :laa_reference,
    :counsel_office_code, :nsm_claim_id,
    :created_at, :updated_at
end
