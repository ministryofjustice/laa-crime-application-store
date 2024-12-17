FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
    service_type { "other" }
    court_type { "other" }
    ufn { "010124/001" }
    office_code { account_number }
    firm_office do
      {
        "account_number" => account_number,
        "address_line_1" => "2 Laywer Suite",
        "address_line_2" => nil,
        "name" => firm_name,
        "postcode" => "CR0 1RE",
        "previous_id" => nil,
        "town" => "Lawyer Town",
        "vat_registered" => "yes",
      }
    end
    solicitor do
      {
        "last_name" => "Doe",
        "first_name" => "John",
        "previous_id" => nil,
        "contact_email" => "john@doe.com",
        "reference_number" => "1234567",
        "contact_last_name" => "Doe",
        "contact_first_name" => "John",
      }
    end
    status { "submitted" }
    updated_at { Time.current }
    created_at { status == "submitted" ? 10.minutes.ago : updated_at }

    transient do
      defendant_name { nil }
      additional_defendant_names { nil }
      firm_name { nil }
      account_number { "1A123B" }
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
        list = [{ first_name:, last_name:, main: true }]

        additional_defendant_names&.each do |defendant_name|
          first_name = defendant_name.present? ? defendant_name.split.first : "Joe"
          last_name = defendant_name.present? ? defendant_name.split(" ", 2).last : "Bloggs"
          list << { first_name:, last_name: }
        end

        list
      end
    end

    trait :with_cost_summary_high_value do
      cost_summary do
        {
          "profit_costs" => {
            "gross_cost" => 5000,
          },
        }
      end
    end

    trait :with_cost_summary_low_value do
      cost_summary do
        {
          "profit_costs" => {
            "gross_cost" => 4999,
          },
        }
      end
    end
  end
end
