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
             :date_received,
             :solicitor_office_code, :solicitor_firm_name,
             :client_last_name,
             :created_at, :updated_at

  many :payment_requests, params: { include_claim: false }
end
