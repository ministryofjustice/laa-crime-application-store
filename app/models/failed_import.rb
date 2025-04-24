class FailedImport < ApplicationRecord
  validates :provider_id, presence: true
end
