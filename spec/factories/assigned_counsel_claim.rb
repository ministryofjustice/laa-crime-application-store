FactoryBot.define do
  factory :assigned_counsel_claim do
    counsel_office_code { "12ZXYZ" }
    laa_reference { "LAA-abc123" }
    ufn { "12022025/001" }
    solicitor_office_code { "12ABCD" }
    client_last_name { "Smith" }
  end
end
