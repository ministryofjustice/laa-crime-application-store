class PaymentRequest < ApplicationRecord
  NSM_REQUEST_TYPES =  %w[
    non_standard_mag
    non_standard_mag_appeal
    non_standard_mag_amendment
    non_standard_mag_supplemental
  ].freeze

  ASSIGNED_COUNSEL_REQUEST_TYPES = %w[
    assigned_counsel
    assigned_counsel_appeal
    assigned_counsel_amendment
  ].freeze

  REQUEST_TYPES = NSM_REQUEST_TYPES + ASSIGNED_COUNSEL_REQUEST_TYPES

  belongs_to :payable, polymorphic: true

  attribute :profit_cost, :gbp
  attribute :travel_cost, :gbp
  attribute :waiting_cost, :gbp
  attribute :disbursement_cost, :gbp
  attribute :net_assigned_counsel_cost, :gbp
  attribute :assigned_counsel_vat, :gbp
  attribute :allowed_profit_cost, :gbp
  attribute :allowed_travel_cost, :gbp
  attribute :allowed_waiting_cost, :gbp
  attribute :allowed_disbursement_cost, :gbp
  attribute :allowed_net_assigned_counsel_cost, :gbp
  attribute :allowed_assigned_counsel_vat, :gbp

  validates :profit_cost, is_a_number: true
  validates :travel_cost, is_a_number: true
  validates :waiting_cost, is_a_number: true
  validates :net_assigned_counsel_cost, is_a_number: true
  validates :assigned_counsel_vat, is_a_number: true
  validates :allowed_profit_cost, is_a_number: true
  validates :allowed_travel_cost, is_a_number: true
  validates :allowed_waiting_cost, is_a_number: true
  validates :allowed_disbursement_cost, is_a_number: true
  validates :allowed_net_assigned_counsel_cost, is_a_number: true
  validates :allowed_assigned_counsel_vat, is_a_number: true
  validates :submitter_id, is_a_uuid: true
  validates :request_type, presence: true, inclusion: { in: REQUEST_TYPES }
  validate :correct_request_type

  def correct_request_type
    return true if payable_type == "NsmClaim" && NSM_REQUEST_TYPES.include?(request_type)
    return true if payable_type == "AssignedCounselClaim" && ASSIGNED_COUNSEL_REQUEST_TYPES.include?(request_type)

    errors.add(:request_type, "invalid payment request type for a #{payable_type}")
  end
end
