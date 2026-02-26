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

  def submitted_at
    application[:submitted_at] || application[:created_at] || raw[:created_at]
  end

  def created_at
    raw[:created_at]
  end

  def updated_at
    raw[:last_updated_at] || application[:updated_at] || raw[:updated_at]
  end

  def payment_request_claim
    @payment_request_claim ||= Crm7SubmissionClaim.new(raw)
  end

private

  def application
    @application ||= raw[:application] || {}
  end
end
