class PaymentRequestClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy
  self.inheritance_column = :type
end
