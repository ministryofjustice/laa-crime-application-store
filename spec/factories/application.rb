FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }

    transient do
      defendant_name { nil }
      first_name { defendant_name.present? ? defendant_name.split.first : "Joe" }
      last_name { defendant_name.present? ? defendant_name.split(" ", 2).last : "Bloggs" }
    end

    trait :pa do
      defendant do
        { first_name:, last_name: }
      end
    end

    trait :nsm do
      defendants do
        [{ first_name:, last_name: }]
      end
    end
  end
end
