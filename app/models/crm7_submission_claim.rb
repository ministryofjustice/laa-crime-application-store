class Crm7SubmissionClaim
  attr_reader :raw

  def initialize(source)
    @raw = build_raw_payload(source)
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

  def client_first_name
    main_defendant&.fetch(:first_name, nil)
  end

  def client_last_name
    main_defendant&.fetch(:last_name, nil)
  end

  def ufn
    application[:ufn]
  end

  def work_completed_date
    application[:work_completed_date]
  end

  def matter_type
    application[:matter_type]
  end

  def youth_court
    application[:youth_court]
  end

  def stage_code
    application[:stage_code] || application[:stage_reached] || application[:claim_type]
  end

  def outcome_code
    application[:outcome_code] || application[:hearing_outcome]
  end

  def court_attendances
    application[:court_attendances]
  end

  def no_of_defendants
    defendants.count
  end

  def court_name
    application[:court]
  end

  def submission_id
    id
  end

  def payment_requests
    []
  end

  def created_at
    raw[:created_at]
  end

  def updated_at
    raw[:updated_at] || raw[:last_updated_at]
  end

  def nsm_claim
    nil
  end

  def assigned_counsel_claim
    nil
  end

private

  def build_raw_payload(source)
    payload =
      if source.is_a?(Submission)
        source.as_json(client_role: :caseworker)
      else
        source
      end

    payload.deep_symbolize_keys
  end

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
    return @main_defendant if defined?(@main_defendant)

    @main_defendant =
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
