#####
# Override linked claim attribute
# create(:payment_request,
#         payment_request_claim: build(:payment_request_claim, :nsm_claim, :stage_code: "PROG") )
#
# No linked payment request claim
# create(:payment_request, payment_request_claim: nil)

FactoryBot.define do
  factory :payment_request do
    id { SecureRandom.uuid }
    request_type { "non_standard_mag" }
    submitter_id { SecureRandom.uuid }
    submitted_at { Time.zone.now }

    trait :non_standard_mag do
      association :payment_request_claim, factory: :nsm_claim
      request_type { "non_standard_mag" }
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
      association :payment_request_claim, factory: :nsm_claim
      request_type { "non_standard_mag_appeal" }
      allowed_profit_cost { 250.40 }
      allowed_travel_cost { 0 }
      allowed_waiting_cost { 6.40 }
      allowed_disbursement_cost { 50 }
    end

    trait :non_standard_mag_supplemental do
      association :payment_request_claim, factory: :nsm_claim
      request_type { "non_standard_mag_supplemental" }
      profit_cost { 300.40 }
      travel_cost { 20.55 }
      waiting_cost { 10.33 }
      disbursement_cost { 100 }
    end

    trait :non_standard_mag_amendment do
      association :payment_request_claim, factory: :nsm_claim
      request_type { "non_standard_mag_amendment" }
      allowed_profit_cost { 250.40 }
      allowed_travel_cost { 0 }
      allowed_waiting_cost { 6.40 }
      allowed_disbursment_cost { 50 }
    end

    trait :assigned_counsel do
      association :payment_request_claim, factory: :assigned_counsel_claim
      request_type { "assigned_counsel" }
      net_assigned_counsel_cost { 100 }
      assigned_counsel_vat { 20 }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end

    trait :assigned_counsel_appeal do
      association :payment_request_claim, factory: :assigned_counsel_claim
      request_type { "assigned_counsel_appeal" }
      net_assigned_counsel_cost { 100 }
      assigned_counsel_vat { 20 }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end

    trait :assigned_counsel_amendment do
      association :payment_request_claim, factory: :assigned_counsel_claim
      request_type { "assigned_counsel_amendment" }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end
  end
end
