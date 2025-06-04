FactoryBot.define do
  factory :failed_import do
    id { SecureRandom.uuid }
    provider_id { SecureRandom.uuid }
    error_type { "UNKNOWN" }
    details { "an error" }
  end
end
