class NsmClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  has_one :assigned_counsel_claim, dependent: :destroy
  has_one :submission
end
