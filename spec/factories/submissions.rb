FactoryBot.define do
  factory :submission do
    id { SecureRandom.uuid }
    state { "submitted" }
    application_risk { "low" }
    application_type { "crm4" }
    current_version { 1 }
    last_updated_at { Time.current }
    caseworker_history_events { [] }
    events { [] }

    transient do
      defendant_name { nil }
      additional_defendant_names { nil }
      firm_name { nil }
      account_number { "1A123B" }
      ufn { nil }
      laa_reference { nil }
      build_scope { [] }
      status { state }
      auto_create_version { true }
    end

    after(:build) do |submission, a|
      if a.auto_create_version
        create(
          :submission_version, *a.build_scope,
          submission:,
          defendant_name: a.defendant_name,
          additional_defendant_names: a.additional_defendant_names,
          firm_name: a.firm_name,
          ufn: a.ufn,
          laa_reference: a.laa_reference,
          account_number: a.account_number,
          status: a.status
        )
      end
    end

    trait :with_pa_version do
      application_type { "crm4" }
      build_scope { [:with_pa_application] }
    end

    trait :with_custom_pa_version do
      application_type { "crm4" }
      build_scope { [:with_custom_pa_application] }
    end

    trait :with_nsm_version do
      application_type { "crm7" }
      build_scope { [:with_nsm_application] }
    end

    trait :with_supplemental_version do
      application_type { "crm7" }
      build_scope { [:with_nsm_supplemental] }
    end
  end
end
