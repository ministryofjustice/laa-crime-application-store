class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  belongs_to :nsm_claim, optional: true

  validates :laa_reference, presence: true
  validates :counsel_office_code, format: { with: /\A[0-9a-zA-Z]+\z/,
    message: "only allows alphanumeric string" }
end
