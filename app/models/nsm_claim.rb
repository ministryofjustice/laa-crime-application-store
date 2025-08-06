class NsmClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  has_one :assigned_counsel_claim, dependent: :destroy
  has_one :submission, dependent: :destroy

  validates :laa_reference,
            presence: true

  validates :ufn, ufn: true, on: :update
  validates :office_code, format: { with: /\A\d[a-zA-Z0-9]*[a-zA-Z]\z/,
                                    message: I18n.t("errors.assigned_counsel_claim.counsel_office_code"),
                                    on: :update }
  validates :stage_code, format: { with: /\A\bPROG\b|\bPROM\b\z/, on: :update }
  validates :court_attendances, :no_of_defendants, numericality: { only_integer: true }, on: :update
end
