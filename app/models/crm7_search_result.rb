class Crm7SearchResult
  attr_reader :raw

  def initialize(raw_record)
    @raw = raw_record.deep_symbolize_keys
  end

  def id
    raw[:application_id] || raw[:id]
  end
  alias_method :submission_id, :id

  def request_type
    raw[:application_type]
  end

  delegate :ufn, to: :payment_request_claim

  delegate :type, to: :payment_request_claim

  def defendant_last_name
    payment_request_claim.client_last_name
  end

  delegate :laa_reference, to: :payment_request_claim

  delegate :solicitor_office_code, to: :payment_request_claim

  delegate :solicitor_firm_name, to: :payment_request_claim

private

  def payment_request_claim
    @payment_request_claim ||= Crm7SubmissionClaim.new(raw)
  end
end
