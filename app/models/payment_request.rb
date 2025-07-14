class PaymentRequest < ApplicationRecord
  def related_records
    self.find_with_ids(self.related_payments)
  end
end
