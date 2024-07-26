FactoryBot.define do
  factory :submission_version do
    json_schema_version { 1 }
    version { 1 }

    transient do
      defendant_name { nil }
      additional_defendant_names { nil }
      firm_name { nil }
      account_number { "1A123B" }
      ufn { nil }
      laa_reference { nil }
    end

    application do
      build(:application,
            defendant_name:,
            firm_name:,
            account_number:,
            ufn: ufn || "010124/001",
            laa_reference: laa_reference || "LAA-123456")
    end

    trait :with_pa_application do
      application do
        build(:application,
              :pa,
              defendant_name:,
              account_number:,
              firm_name:,
              ufn: ufn || "010124/001",
              service_type: "ae_consultant",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_custom_pa_application do
      application do
        build(:application,
              :pa,
              defendant_name:,
              account_number:,
              firm_name:,
              ufn: ufn || "010124/001",
              service_type: "custom",
              custom_service_name: "Test")
      end
    end

    trait :with_nsm_application do
      application do
        build(:application,
              :nsm,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end
  end
end
