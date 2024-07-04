FactoryBot.define do
  factory :submission_version do
    json_schema_version { 1 }
    version { 1 }
    application factory: :application, strategy: :build
  end

  trait :with_pa_application do
    application factory: %i[application pa], strategy: :build
  end

  trait :with_nsm_application do
    application factory: %i[application pa], strategy: :build
  end
end
