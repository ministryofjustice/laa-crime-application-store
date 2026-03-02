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

  def ufn
    payment_request_claim.ufn
  end

  def type
    payment_request_claim.type
  end

  def defendant_last_name
    payment_request_claim.client_last_name
  end

  def laa_reference
    payment_request_claim.laa_reference
  end

  def solicitor_office_code
    payment_request_claim.solicitor_office_code
  end

  def solicitor_firm_name
    payment_request_claim.solicitor_firm_name
  end
private

  def payment_request_claim
    @payment_request_claim ||= Crm7SubmissionClaim.new(raw)
  end

  def application
    @application ||= raw[:application] || {}
  end
end
