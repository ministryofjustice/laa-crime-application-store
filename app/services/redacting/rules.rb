module Redacting
  module Rules
    REDACTED_KEYWORD = "__redacted__".freeze

    PII_ATTRIBUTES = {
      "defendant" => {
        redact: %w[date_of_birth first_name last_name],
        # I've said this data is an object and constructed as so but it may infact be an array
        type: :object,
      },
      "some_array" => {
        redact: %w[item_one],
        type: :array, # [{}, {}, ...]
      },
      "some_string" => {
        redact: :value,
        type: :string,
      },
    }.freeze

    def self.pii_attributes
      PII_ATTRIBUTES
    end
  end
end
