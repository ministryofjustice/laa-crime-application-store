FactoryBot.define do
  factory :submission_version do
    json_schema_version { 1 }
    version { 1 }

    transient do
      defendant_name { nil }
      firm_name { nil }
      ufn { nil }
    end
    application { build(:application, defendant_name:, firm_name:, ufn: ufn || "010124/001") }

    trait :with_pa_application do
      application { build(:application, :pa, defendant_name:, firm_name:, ufn: ufn || "010124/001", service_type: 'ae_consultant') }
    end

    trait :with_nsm_application do
      application { build(:application, :nsm, defendant_name:, firm_name:, ufn: ufn || "010124/001") }
    end
  end
end
