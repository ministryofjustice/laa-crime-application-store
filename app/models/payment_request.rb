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

  belongs_to :payable, polymorphic: true, optional: true

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

  validates :profit_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :travel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :waiting_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :net_assigned_counsel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :assigned_counsel_vat, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_profit_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_travel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_waiting_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_disbursement_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_net_assigned_counsel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_assigned_counsel_vat, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :submitter_id, is_a_uuid: true
  validates :request_type, presence: true, inclusion: { in: REQUEST_TYPES }
  validate :correct_request_type
  validate :is_linked_to_claim_when_submitted

  def correct_request_type
    # needed so that we can draft payment types that haven't been linked yet
    return true if payable_type.nil? && REQUEST_TYPES.include?(request_type)
    return true if payable_type == "NsmClaim" && NSM_REQUEST_TYPES.include?(request_type)
    return true if payable_type == "AssignedCounselClaim" && ASSIGNED_COUNSEL_REQUEST_TYPES.include?(request_type)

    errors.add(:request_type, "invalid payment request type for a #{payable_type}")
  end

  def is_linked_to_claim_when_submitted
    if payable_id.nil? && submitted_at.present?
      errors.add(:submitted_at, "a payment request must be linked to a claim to be submitted")
    else
      true
    end
  end
end
