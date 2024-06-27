FactoryBot.define do
  factory :event_submission, class: 'Submission' do
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
    after(:create) do |submission, _a|
      create(:submission_version, submission:)
    end
  end
end
