FactoryBot.define do
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

    trait :decision do
      event_type { "decision" }
    end

    trait :auto_decision do
      event_type { "auto_decision" }
    end
  end
end
