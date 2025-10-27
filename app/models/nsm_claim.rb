class NsmClaim < PaymentRequestClaim
  has_one :assigned_counsel_claim, -> { where(type: "AssignedCounselClaim") },
          class_name: "AssignedCounselClaim",
          foreign_key: :nsm_claim_id,
          inverse_of: :nsm_claim,
          dependent: :destroy
  has_one :submission, dependent: :destroy

  validates :laa_reference, presence: true
  validates :ufn, ufn: true, on: :update
  validates :solicitor_office_code, office_code: true
  validates :stage_code, format: { with: /\A\bPROG\b|\bPROM\b\z/, on: :update }
  validates :court_attendances, :no_of_defendants, numericality: { only_integer: true }, on: :update
  validates :solicitor_firm_name, presence: true
  validates :client_first_name, presence: true
  validates :client_last_name, presence: true
  validates :outcome_code, presence: true
  validates :matter_type, presence: true
  validates :court_name, presence: true
  validates :youth_court, inclusion: { in: [true, false] }
  validates :ufn, presence: true, ufn: true
  validates :work_completed_date, presence: true
  validates :stage_code, format: { with: /\A\bPROG\b|\bPROM\b\z/ }
  validates :court_attendances, :no_of_defendants, numericality: { only_integer: true }
end
