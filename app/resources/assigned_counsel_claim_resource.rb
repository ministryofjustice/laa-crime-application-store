class AssignedCounselClaimResource
  include Alba::Resource

  root_key :assigned_counsel_claim

  attribute :claim_type do |resource|
    resource.class.name.to_s
  end

  attributes :id,
             :laa_reference,
             :counsel_office_code, :counsel_firm_name,
             :nsm_claim_id, :ufn,
             :client_last_name,
             :solicitor_office_code, :solicitor_firm_name,
             :created_at, :updated_at

  attribute :linked_crm8_laa_reference do |resource|
    resource.nsm_claim.laa_reference
  end

  many :payment_requests, params: { include_claim: false }
end
