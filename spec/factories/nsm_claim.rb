FactoryBot.define do
  factory :nsm_claim do
    id { SecureRandom.uuid }
    laa_reference { "LAA-Xcoqqz" }
    ufn { "120423/001" }
    date_received { Time.zone.now }
    firm_name { "Solicitor Firm" }
    office_code { "1A123B" }
    stage_code { "PROM" }
    client_first_name { "Tom" }
    client_last_name { "Smith" }
    work_completed_date { 1.day.ago }
    outcome_code { "CP01" }
    matter_type { "1" }
    youth_court { true }
    court_name { "Leeds Court" }
    court_attendances { 2 }
    no_of_defendants { 1 }
  end
end
