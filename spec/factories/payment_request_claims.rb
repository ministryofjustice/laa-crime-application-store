FactoryBot.define do
  factory :payment_request_claim do
    id { SecureRandom.uuid }
    laa_reference { "LAA-Xcoqqz" }
    client_last_name  { "Smith" }
    date_received     { Time.zone.today }
    office_code { "1A123B" }
    ufn { "120423/001" }

    factory :nsm_claim, class: "NsmClaim" do
      firm_name { "Solicitor Firm" }
      stage_code { "PROM" }
      client_first_name { "Tom" }
      work_completed_date { 1.day.ago }
      outcome_code { "CP01" }
      matter_type { "1" }
      youth_court { true }
      court_name { "Leeds Court" }
      court_attendances { 2 }
      no_of_defendants { 1 }
    end

    factory :assigned_counsel_claim, class: "AssignedCounselClaim" do
      nsm_claim
      solicitor_office_code { "12ABCD" }
    end
  end
end
