FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
  end

  trait :pa do
    defendant do
      { first_name: "Joe", last_name: "Bloggs" }
    end
  end

  trait :nsm do
    defendants do
      [
        {
          first_name => "Joe",
          last_name => "Bloggs",
        },
      ]
    end
  end
end
