FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
  end

  trait :pa do
    defendant {
      {first_name: 'Joe', last_name: 'Bloggs'}
    }
  end

  trait :nsm do
    defendants {
      [
        {
          first_name => 'Joe',
          last_name => 'Bloggs'
        }
      ]
    }
  end
end
