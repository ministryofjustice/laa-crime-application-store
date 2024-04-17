FactoryBot.define do
  factory :submission_version do
    json_schema_version { 1 }
    version { 1 }
    application factory: :application_data, strategy: :build
  end

  factory :application_data, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
  end
end
