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

    trait :with_custom_pa_version do
      build_scope { [:with_custom_pa_application] }
    end

    trait :with_nsm_version do
      build_scope { [:with_nsm_application] }
    end
  end

  factory :event, class: Hash do
    initialize_with { attributes }
    id { SecureRandom.uuid }
    public { false }
    details { {} }
    linked_id { nil }
    event_type { "new_version" }
    linked_type { nil }
    primary_user_id { nil }
    secondary_user_id { nil }
    submission_version { 1 }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }

    trait :new_version do
      event_type { "new_version" }
    end

    trait :assignment do
      event_type { "assignment" }
      primary_user_id { SecureRandom.uuid }
    end

    trait :unassignment do
      event_type { "unassignment" }
      primary_user_id { SecureRandom.uuid }
      details { { comment: "wrongly assigned" } }
    end
  end
end
