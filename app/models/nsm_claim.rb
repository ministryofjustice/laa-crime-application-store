class NsmClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  has_one :assigned_counsel_claim, dependent: :destroy
  has_one :submission, dependent: :destroy

  validates :laa_reference,
            presence: true

  validates :ufn, ufn: true, on: :update
  validates :office_code, office_code: true, on: :update
  validates :stage_code, format: { with: /\A\bPROG\b|\bPROM\b\z/, on: :update }
  validates :court_attendances, :no_of_defendants, numericality: { only_integer: true }, on: :update
end
