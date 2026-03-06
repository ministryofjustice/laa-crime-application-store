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
    main_defendant&.fetch(:last_name, nil)
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

  def defendants
    @defendants ||= Array(application[:defendants]).map do |defendant|
      defendant.is_a?(Hash) ? defendant.deep_symbolize_keys : defendant
    end
  end

  def main_defendant
    @main_defendant ||=
      if defendants.any?
        defendants.find { |defendant| truthy?(defendant[:main]) } || defendants.first
      else
        value = application[:defendant]
        value.is_a?(Hash) ? value.deep_symbolize_keys : value
      end
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
