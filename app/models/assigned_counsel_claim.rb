class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  belongs_to :nsm_claim
end
