class AssignedCounselClaim < PaymentRequestClaim
  belongs_to :nsm_claim,
             class_name: "NsmClaim",
             inverse_of: :assigned_counsel_claim,
             optional: true

  validates :nsm_claim_id, presence: true
  validates :solicitor_office_code, office_code: true
end
