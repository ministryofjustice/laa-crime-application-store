class Subscriber < ApplicationRecord
  self.table_name = "subscriber"

  validates :webhook_url, presence: true, uniqueness: { scope: :subscriber_type }
  validates :subscriber_type, presence: true
end
