FactoryBot.define do
  factory :application, class: Hash do
    initialize_with { attributes }
    laa_reference { "LAA-123456" }
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
    status { "submitted" }
    updated_at { Time.current }
    created_at { status == "submitted" ? 10.minutes.ago : updated_at }

    transient do
      defendant_name { nil }
      additional_defendant_names { nil }
      firm_name { nil }
      account_number { "1A123B" }
      maat { "1234567" }
      first_name { defendant_name.present? ? defendant_name.split.first : "Joe" }
      last_name { defendant_name.present? ? defendant_name.split(" ", 2).last : "Bloggs" }
    end

    trait :pa do
      court_type { "other" }
      service_type { "other" }
      defendant do
        { first_name:, last_name: }
      end
      solicitor do
        {
          "previous_id" => nil,
          "contact_email" => "john@doe.com",
          "reference_number" => "1234567",
          "contact_last_name" => "Doe",
          "contact_first_name" => "John",
        }
      end
      quotes do
        [
          {
            "primary" => true,
            "contact_first_name" => "Joe",
            "contact_last_name" => "Bloggs",
            "organisation" => "LAA",
            "postcode" => "CRO 1RE",
            "cost_per_hour" => 10,
            "period" => 180,
            "travel_cost_reason" => "a reason",
            "travel_cost_per_hour" => 50.0,
            "travel_time" => 150,
            "cost_type" => "per_hour",
            "related_to_post_mortem" => true,
          },
        ]
      end
      additional_costs do
        [
          {
            "name" => "stuff",
            "description" => "some extra stuff",
            "items" => 2,
            "cost_per_item" => 10.0,
            "unit_type" => "per_item",
          },
        ]
      end
    end

    trait :per_item_quote do
      quotes do
        [
          {
            "primary" => true,
            "contact_first_name" => "Joe",
            "contact_last_name" => "Bloggs",
            "organisation" => "LAA",
            "postcode" => "CRO 1RE",
            "cost_per_item" => 20,
            "items" => 10,
            "travel_cost_reason" => "a reason",
            "travel_cost_per_hour" => 50.0,
            "travel_time" => 150,
            "cost_type" => "per_item",
            "cost_multiplier" => 1,
            "related_to_post_mortem" => true,
          },
        ]
      end
    end

    trait :no_travel_cost_quote do
      quotes do
        [
          {
            "primary" => true,
            "contact_first_name" => "Joe",
            "contact_last_name" => "Bloggs",
            "organisation" => "LAA",
            "postcode" => "CRO 1RE",
            "cost_per_item" => 20,
            "items" => 10,
            "travel_cost_reason" => nil,
            "cost_type" => "per_item",
            "cost_multiplier" => 1,
            "related_to_post_mortem" => true,
          },
        ]
      end
    end

    trait :per_hour_additional_cost do
      additional_costs do
        [
          {
            "name" => "stuff",
            "description" => "some extra stuff",
            "period" => 180,
            "cost_per_hour" => 10.0,
            "unit_type" => "per_hour",
          },
        ]
      end
    end

    trait :nsm_breach_type do
      claim_type { "breach_of_injunction" }
      cntp_order { "CNTP100" }
      cntp_date { Time.zone.local(2025, 2, 2) }
    end

    trait :nsm do
      claim_type { "non_standard_magistrate" }
      rep_order_date { Time.zone.local(2025, 1, 1) }
      work_completed_date { Time.zone.local(2025, 1, 1) }
      hearing_outcome { "CP01" }
      matter_type { "1" }
      youth_court { true }
      letters { 500 }
      calls { 220 }
      letters_uplift { 10 }
      calls_uplift { 20 }
      reasons_for_claim { [] }
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
      work_items do
        [
          {
            "uplift" => 0,
            "position" => 1,
            "work_type" => "preparation",
            "fee_earner" => "AB",
            "time_spent" => 200,
            "completed_on" => "2024-01-01",
          },
        ]
      end

      disbursements do
        [
          {
            "disbursement_date" => Time.zone.local(2025, 1, 1),
            "disbursement_type" => "motorcycle",
            "miles" => 120.45,
            "position" => 1,
            "details" => "Drive to court",
            "other_type" => nil,
            "vat_rate" => 0.2,
            "total_cost_without_vat" => 350.33,
            "apply_vat" => true,
          },
        ]
      end

      defendants do
        list = [{ first_name:, last_name:, maat:, main: true }]

        additional_defendant_names&.each do |defendant_name|
          first_name = defendant_name.present? ? defendant_name.split.first : "Joe"
          last_name = defendant_name.present? ? defendant_name.split(" ", 2).last : "Bloggs"
          list << { first_name:, last_name:, maat: }
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

    trait :with_high_value do
      cost_summary do
        {
          "high_value" => true,
        }
      end
    end

    trait :with_low_value do
      cost_summary do
        {
          "high_value" => false,
        }
      end
    end
  end
end
