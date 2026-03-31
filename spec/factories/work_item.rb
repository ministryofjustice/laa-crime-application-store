FactoryBot.define do
  factory :work_item, class: Hash do
    initialize_with { attributes }
    id { SecureRandom.uuid }
    position { 1 }
    uplift { nil }
    pricing { 65.42 }
    time_spent { 60 }
    completed_on { Date.current.iso8601 }
    work_type { { 'en' => 'Advocacy', 'value' => 'advocacy' } }
    fee_earner { 'Joe Bloggs' }
  end
end
