class AssignedCounselClaim < ApplicationRecord
  has_many :payment_requests, dependent: :destroy, inverse_of: :payable, as: :payable
  belongs_to :nsm_claim, optional: true

  validates :laa_reference, presence: true
  validates :counsel_office_code, format: { with: /\A\d[a-zA-Z0-9]*[a-zA-Z]\z/,
                                            message: I18n.t("errors.assigned_counsel_claim.counsel_office_code") }
end
