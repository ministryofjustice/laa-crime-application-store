module Redacting
  module Rules
    REDACTED_KEYWORD = "__redacted__".freeze

    PII_ATTRIBUTES = {
      "case_details.codefendants" => {
        redact: %w[first_name last_name],
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
