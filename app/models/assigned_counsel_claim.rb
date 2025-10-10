class AssignedCounselClaim < PaymentRequestClaim
  belongs_to :nsm_claim,
             -> { where(type: "NsmClaim") },
             class_name: "NsmClaim",
             foreign_key: :nsm_claim_id,
             inverse_of: :assigned_counsel_claim,
             optional: true

  validates :nsm_claim_id, presence: true
  validates :date_received, presence: true
  validates :solicitor_office_code, presence: true
end
