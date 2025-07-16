class PaymentRequest < ApplicationRecord
  belongs_to :payable, polymorphic: true
end
