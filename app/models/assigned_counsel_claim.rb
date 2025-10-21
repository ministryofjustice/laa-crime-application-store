class AssignedCounselClaim < PaymentRequestClaim
  belongs_to :nsm_claim,
             -> { where(type: "NsmClaim") },
             class_name: "NsmClaim",
             foreign_key: :nsm_claim_id,
             inverse_of: :assigned_counsel_claim,
             optional: true

  validates :laa_reference, presence: true
  validates :counsel_office_code, office_code: true, on: :update
  validates :solicitor_office_code, office_code: true
end
