FactoryBot.define do
  factory :event_submission, class: "Submission" do
    id { SecureRandom.uuid }
    application_state { "submitted" }
    application_risk { "low" }
    application_type { "crm4" }
    current_version { 1 }
  end

  factory :submission do
    id { SecureRandom.uuid }
    application_state { "submitted" }
    application_risk { "low" }
    application_type { "crm4" }
    current_version { 1 }
    events { [] }

    transient do
      defendant_name { nil }
      firm_name { nil }
      ufn { nil }
      build_scope { [] }
    end

    after(:build) do |submission, a|
      create(
        :submission_version, *a.build_scope,
        submission:,
        defendant_name: a.defendant_name,
        firm_name: a.firm_name,
        ufn: a.ufn
      )
    end

    trait :with_pa_version do
      build_scope { [:with_pa_application] }
    end

    trait :with_nsm_version do
      build_scope { [:with_nsm_application] }
    end
  end
end
