class NsmClaim < ApplicationRecord
  has_many :payment_requests, as: :payable
  has_one :assigned_counsel_claim
end
