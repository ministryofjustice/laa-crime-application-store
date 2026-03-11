class Crm7SubmissionClaim
  attr_reader :raw

  def initialize(source)
    @raw = source.deep_symbolize_keys
  end

  def id
    raw[:id] || raw[:application_id]
  end

  def type
    self.class.name
  end

  def laa_reference
    application[:laa_reference]
  end

  def solicitor_office_code
    firm_office[:account_number]
  end

  def solicitor_firm_name
    firm_office[:name]
  end

  def client_last_name
    main_defendant[:last_name]
  end

  def ufn
    application[:ufn]
  end

private

  def application
    @application ||= raw[:application] || {}
  end

  def firm_office
    @firm_office ||= application[:firm_office] || {}
  end

  def main_defendant
    @main_defendant ||= application[:defendants].find { _1[:main] }
  end
end
