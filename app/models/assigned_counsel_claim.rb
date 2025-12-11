class AssignedCounselClaim < PaymentRequestClaim
  belongs_to :nsm_claim,
             class_name: "NsmClaim",
             inverse_of: :assigned_counsel_claim,
             optional: true

  validates :ufn, presence: true, ufn: true
  validates :laa_reference, presence: true
  validates :counsel_office_code, office_code: true, presence: true
  validates :solicitor_office_code, office_code: true, presence: true
  validates :solicitor_firm_name, office_code: true, presence: true
  validates :client_last_name, presence: true
end
