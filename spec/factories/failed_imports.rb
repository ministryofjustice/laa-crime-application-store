FactoryBot.define do
  factory :failed_import do
    id { SecureRandom.uuid }
    provider_id { SecureRandom.uuid }
    details { "an error" }
  end
end
