FactoryBot.define do
  factory :submission_version do
    json_schema_version { 1 }
    version { 1 }
    application factory: :application_data, strategy: :build
    # after(:create) do |version, _a|
    #   create(:redacted_submission_version, version:)
    # end
  end

  factory :application_data, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
  end
end
