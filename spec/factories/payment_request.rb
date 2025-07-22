FactoryBot.define do
  factory :payment_request do
    id { SecureRandom.uuid }
    submitter_id { SecureRandom.uuid }
    request_type { "non_standard_mag" }
    payable_type { "NsmClaim" }
    submitted_at { Time.zone.now }

    trait :non_standard_mag do
      request_type { "non_standard_mag" }
      payable_type { "NsmClaim" }
      profit_cost { 300.40 }
      travel_cost { 20.55 }
      waiting_cost { 10.33 }
      disbursement_cost { 100 }
      allowed_profit_cost { 250.40 }
      allowed_travel_cost { 0 }
      allowed_waiting_cost { 6.40 }
      allowed_disbursement_cost { 50 }
    end

    trait :non_standard_mag_appeal do
      request_type { "non_standard_mag_appeal" }
      payable_type { "NsmClaim" }
      allowed_profit_cost { 250.40 }
      allowed_travel_cost { 0 }
      allowed_waiting_cost { 6.40 }
      allowed_disbursement_cost { 50 }
    end

    trait :non_standard_mag_supplemental do
      request_type { "non_standard_mag_supplemental" }
      payable_type { "NsmClaim" }
      profit_cost { 300.40 }
      travel_cost { 20.55 }
      waiting_cost { 10.33 }
      disbursement_cost { 100 }
    end

    trait :non_standard_mag_amendment do
      request_type { "non_standard_mag_amendment" }
      payable_type { "NsmClaim" }
      allowed_profit_cost { 250.40 }
      allowed_travel_cost { 0 }
      allowed_waiting_cost { 6.40 }
      allowed_disebursment_cost { 50 }
    end

    trait :assigned_counsel do
      request_type { "assigned_counsel" }
      payable_type { "AssignedCounselClaim" }
      net_assigned_counsel_cost { 100 }
      assigned_counsel_vat { 20 }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end

    trait :assigned_counsel_appeal do
      request_type { "assigned_counsel_appeal" }
      payable_type { "AssignedCounselClaim" }
      net_assigned_counsel_cost { 100 }
      assigned_counsel_vat { 20 }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end

    trait :assigned_counsel_amendment do
      request_type { "assigned_counsel_amendment" }
      payable_type { "AssignedCounselClaim" }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end
  end
end
