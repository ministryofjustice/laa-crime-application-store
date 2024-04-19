module Redacting
  module Rules
    REDACTED_KEYWORD = "__redacted__".freeze

    PII_ATTRIBUTES = {
      "provider_details" => {
        redact: %w[legal_rep_telephone],
      },
      "client_details.applicant" => {
        redact: %w[first_name last_name other_names nino telephone_number],
      },
      "client_details.applicant.home_address" => {
        redact: %w[lookup_id address_line_one address_line_two],
      },
      "client_details.applicant.correspondence_address" => {
        redact: %w[lookup_id address_line_one address_line_two],
      },
      "case_details.codefendants" => {
        redact: %w[first_name last_name],
        type: :array, # [{}, {}, ...]
      },
      "interests_of_justice" => {
        redact: %w[reason],
        type: :array, # [{}, {}, ...]
      },
      "supporting_evidence" => {
        redact: %w[s3_object_key filename],
        type: :array, # [{}, {}, ...]
      },
      "additional_information" => {
        redact: :value,
        type: :string,
      },
    }.freeze

    def self.pii_attributes
      PII_ATTRIBUTES
    end
  end
end
