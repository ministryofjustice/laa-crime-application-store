class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, as: :payable
  belongs_to :nsm_claim
