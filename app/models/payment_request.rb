class PaymentRequest < ApplicationRecord
  NSM_REQUEST_TYPES =  %w[
    breach_of_injunction
    non_standard_magistrate
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

  belongs_to :payable_claim, optional: false

  belongs_to :nsm_claim,
             class_name: "NsmClaim",
             foreign_key: :payable_claim_id,
             optional: true

  belongs_to :ac_claim,
             class_name: "AssignedCounselClaim",
             foreign_key: :payable_claim_id,
             optional: true

  attribute :claimed_profit_cost, :gbp
  attribute :allowed_profit_cost, :gbp
  attribute :claimed_travel_cost, :gbp
  attribute :allowed_travel_cost, :gbp
  attribute :claimed_waiting_cost, :gbp
  attribute :allowed_waiting_cost, :gbp
  attribute :claimed_disbursement_cost, :gbp
  attribute :allowed_disbursement_cost, :gbp

  attribute :claimed_total, :gbp
  attribute :allowed_total, :gbp

  attribute :claimed_net_assigned_counsel_cost, :gbp
  attribute :claimed_assigned_counsel_vat, :gbp
  attribute :allowed_net_assigned_counsel_cost, :gbp
  attribute :allowed_assigned_counsel_vat, :gbp

  validates :submitter_id, is_a_uuid: true
  validates :request_type, presence: true, inclusion: { in: REQUEST_TYPES }
  validates :claimed_profit_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :claimed_travel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :claimed_waiting_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :claimed_disbursement_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :claimed_net_assigned_counsel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :claimed_assigned_counsel_vat, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_profit_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_travel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_waiting_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_disbursement_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_net_assigned_counsel_cost, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :allowed_assigned_counsel_vat, is_a_number: true, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :correct_request_type

  def nsm_claim
    payable_claim.is_a?(NsmClaim) ? payable_claim : nil
  end

  def nsm_claim=(record)
    self.payable_claim = record
  end

  def assigned_counsel_claim
    payable_claim.is_a?(AssignedCounselClaim) ? payable_claim : nil
  end

  def assigned_counsel_claim=(record)
    self.payable_claim = record
  end

  def correct_request_type
    return true if nsm_claim && NSM_REQUEST_TYPES.include?(request_type)
    return true if assigned_counsel_claim && ASSIGNED_COUNSEL_REQUEST_TYPES.include?(request_type)

    # :nocov:
    if payable_claim
      errors.add(:request_type, "invalid request type for a #{payable_claim.type}")
    end
    # :nocov:
  end
end
