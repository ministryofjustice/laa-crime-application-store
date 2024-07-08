FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
    ufn { "010124/001" }
    firm_office do
      {
        "account_number" => "1A123B",
        "address_line_1" => "2 Laywer Suite",
        "address_line_2" => nil,
        "name" => firm_name,
        "postcode" => "CR0 1RE",
        "previous_id" => nil,
        "town" => "Lawyer Town",
        "vat_registered" => "yes",
      }
    end

    transient do
      defendant_name { nil }
      firm_name { nil }
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
