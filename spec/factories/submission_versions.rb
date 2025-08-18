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
      status { "submitted" }
      high_value { false }
    end

    application do
      build(:application,
            defendant_name:,
            firm_name:,
            account_number:,
            status:,
            high_value:,
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
              status:,
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
              status:,
              ufn: ufn || "010124/001",
              service_type: "custom",
              custom_service_name: "Test")
      end
    end

    trait :with_per_item_quote_pa_application do
      application do
        build(:application,
              :pa,
              :per_item_quote,
              defendant_name:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              service_type: "custom",
              custom_service_name: "Test")
      end
    end

    trait :with_no_travel_cost_quote_pa_application do
      application do
        build(:application,
              :pa,
              :no_travel_cost_quote,
              defendant_name:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              service_type: "custom",
              custom_service_name: "Test")
      end
    end

    trait :with_per_hour_additional_cost_pa_application do
      application do
        build(:application,
              :pa,
              :per_hour_additional_cost,
              defendant_name:,
              account_number:,
              firm_name:,
              status:,
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
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_breach_application do
      application do
        build(:application,
              :nsm,
              :nsm_breach_type,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              maat: nil,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_application_no_cost_summary do
      application do
        build(:application,
              :nsm,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_application_high_gross_cost do
      application do
        build(:application,
              :nsm,
              :with_cost_summary_high_value,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_application_low_gross_cost do
      application do
        build(:application,
              :nsm,
              :with_cost_summary_low_value,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_application_high_value do
      application do
        build(:application,
              :nsm,
              :with_high_value,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_application_low_value do
      application do
        build(:application,
              :nsm,
              :with_low_value,
              defendant_name:,
              additional_defendant_names:,
              account_number:,
              firm_name:,
              status:,
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end

    trait :with_nsm_supplemental do
      application do
        build(:application,
              :nsm,
              defendant_name:,
              account_number:,
              firm_name:,
              status:,
              supplemental_claim: "yes",
              ufn: ufn || "010124/001",
              laa_reference: laa_reference || "LAA-123456")
      end
    end
  end
end
