class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  belongs_to :nsm_claim, optional: true

  validates :laa_reference, presence: true
  validates :counsel_office_code, office_code: true, on: :update
end
