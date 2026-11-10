class PayableClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy
  scope :client_full_name_is, lambda { |full_name|
    where("LOWER(client_first_name || ' ' || client_last_name) = ?", full_name.downcase)
  }
  self.inheritance_column = :type
end
