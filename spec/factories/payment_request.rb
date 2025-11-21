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
    request_type { "non_standard_magistrate" }
    submitter_id { SecureRandom.uuid }
    submitted_at { Time.zone.now }
    submission_id { nil }

    trait :non_standard_magistrate do
      association :payment_request_claim, factory: :nsm_claim
      request_type { "non_standard_magistrate" }
      claimed_profit_cost { 300.40 }
      claimed_travel_cost { 20.55 }
      claimed_waiting_cost { 10.33 }
      claimed_disbursement_cost { 100 }
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
      claimed_profit_cost { 300.40 }
      claimed_travel_cost { 20.55 }
      claimed_waiting_cost { 10.33 }
      claimed_disbursement_cost { 100 }
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
      claimed_net_assigned_counsel_cost { 100 }
      claimed_assigned_counsel_vat { 20 }
      allowed_net_assigned_counsel_cost { 50 }
      allowed_assigned_counsel_vat { 10 }
    end

    trait :assigned_counsel_appeal do
      association :payment_request_claim, factory: :assigned_counsel_claim
      request_type { "assigned_counsel_appeal" }
      claimed_net_assigned_counsel_cost { 100 }
      claimed_assigned_counsel_vat { 20 }
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
