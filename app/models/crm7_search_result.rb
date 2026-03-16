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

  delegate :ufn, to: :payable_claim

  delegate :type, to: :payable_claim

  def defendant_last_name
    payable_claim.client_last_name
  end

  delegate :laa_reference, to: :payable_claim

  delegate :solicitor_office_code, to: :payable_claim

  delegate :solicitor_firm_name, to: :payable_claim

private

  def payable_claim
    @payable_claim ||= Crm7SubmissionClaim.new(raw)
  end
end
