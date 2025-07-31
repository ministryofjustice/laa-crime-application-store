class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  belongs_to :nsm_claim, optional: true

  validates :laa_reference, presence: true
  validates :counsel_office_code, format: { with: /\A\d[a-zA-Z0-9]*[a-zA-Z]\z/,
    message: "only allows alphanumeric string starting with a number and ending in a letter" }
end
