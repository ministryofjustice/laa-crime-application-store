FactoryBot.define do
  factory :submission do
    application_id { SecureRandom.uuid }
    application_state { "submitted" }
    application_risk { "low" }
    application_type { "crm4" }
    events { [] }
    assigned_user_id { nil }
    unassigned_user_ids { [] }
    submission_versions { [build(:submission_version)] }
  end
end
