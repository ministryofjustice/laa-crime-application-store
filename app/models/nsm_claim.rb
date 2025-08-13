class NsmClaim < PaymentRequestClaim
  has_one :assigned_counsel_claim, -> { where(type: "AssignedCounselClaim") },
          class_name: "AssignedCounselClaim",
          foreign_key: :nsm_claim_id,
          inverse_of: :nsm_claim,
          dependent: :destroy
  has_one :submission, dependent: :destroy

  validates :laa_reference, presence: true
  validates :ufn, ufn: true, on: :update
  validates :office_code, office_code: true, on: :update
  validates :stage_code, format: { with: /\A\bPROG\b|\bPROM\b\z/, on: :update }
  validates :court_attendances, :no_of_defendants, numericality: { only_integer: true }, on: :update

  def self.where_terms string
    PaymentRequestSearch.new(string)
  end
end
