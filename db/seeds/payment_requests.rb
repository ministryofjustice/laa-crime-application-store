require "securerandom"
require "bigdecimal"

raise "payment seeds are dev-only (#{Rails.env})" unless Rails.env.development?

def d(num) = BigDecimal(num)

# -------------------------------------
# RANDOM DATA POOLS
# -------------------------------------
SOLICITOR_FIRMS = [
  "Blackstone & Co LLP",
  "Murray Legal Services",
  "Inverclyde Defence",
  "Andrews Solicitors",
  "Hughes & Partners",
  "Ayrshire Justice Group"
]

COURTS = [
  "Glasgow Sheriff Court",
  "Paisley Sheriff Court",
  "Greenock JP Court",
  "Edinburgh Sheriff Court",
  "Hamilton Sheriff Court"
]

MATTER_TYPES = %w[CF AC MT YC AD]
OUTCOME_CODES = %w[GR REF WDR CON DEC]

# -------------------------------------
# SHARED CLAIM DEFAULT GENERATOR
# -------------------------------------
def claim_defaults
  {
    solicitor_firm_name: SOLICITOR_FIRMS.sample,
    matter_type: MATTER_TYPES.sample,
    outcome_code: OUTCOME_CODES.sample,
    court_name: COURTS.sample,
    youth_court: [true, false].sample,
    work_completed_date: rand(10..40).days.ago.to_date,
    court_attendances: rand(1..5),
    no_of_defendants: rand(1..3)
  }
end

# -------------------------------------
# HELPERS: FACTORY METHODS
# -------------------------------------

def create_nsm(attrs)
  NsmClaim.create!(attrs.merge(claim_defaults))
end

def create_ac(attrs)
  AssignedCounselClaim.create!(attrs.merge(claim_defaults))
end

def create_payment_request(attrs)
  PaymentRequest.create!(attrs)
end

# -------------------------------------
# WIPE EXISTING
# -------------------------------------
puts "== Wiping existing data =="
ActiveRecord::Base.transaction do
  PaymentRequest.destroy_all
  PaymentRequestClaim.destroy_all
end
puts "Wipe complete."

puts "== Seeding 21 PaymentRequests =="

# -------------------------------------
# NSM CLAIMS (12)
# -------------------------------------

ActiveRecord::Base.transaction do

  # -------------------------
  # NSM CLAIMS
  # -------------------------

  nsm1 = create_nsm(
    laa_reference: "LAA-0001",
    ufn: "010101/001",
    solicitor_office_code: "1A123B",
    stage_code: "PROG",
    client_first_name: "Ava",
    client_last_name: "Andrews"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_magistrate",
    submitted_at: 25.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm1,
    claimed_profit_cost: d("300.40"),
    claimed_travel_cost: d("20.55"),
    claimed_waiting_cost: d("10.33"),
    claimed_disbursement_cost: d("100.00"),
    allowed_profit_cost: d("250.40"),
    allowed_travel_cost: d("0.00"),
    allowed_waiting_cost: d("6.40"),
    allowed_disbursement_cost: d("50.00")
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_supplemental",
    submitted_at: 24.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm1,
    allowed_profit_cost: d("300.40"),
    allowed_travel_cost: d("0.00"),
    allowed_waiting_cost: d("6.40"),
    allowed_disbursement_cost: d("50.00")
  )

  nsm2 = create_nsm(
    laa_reference: "LAA-0002",
    ufn: "020101/002",
    solicitor_office_code: "1A123B",
    stage_code: "PROM",
    client_first_name: "Ben",
    client_last_name: "Blake"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_magistrate",
    submitted_at: 22.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm2,
    claimed_profit_cost: d("420.00"),
    claimed_travel_cost: d("35.00"),
    claimed_waiting_cost: d("0.00"),
    claimed_disbursement_cost: d("80.00"),
    allowed_profit_cost: d("380.00"),
    allowed_travel_cost: d("20.00"),
    allowed_waiting_cost: d("0.00"),
    allowed_disbursement_cost: d("60.00")
  )

  nsm3 = create_nsm(
    laa_reference: "LAA-0003",
    ufn: "030101/003",
    solicitor_office_code: "2B456C",
    stage_code: "PROG",
    client_first_name: "Carla",
    client_last_name: "Carter"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_appeal",
    submitted_at: 20.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm3,
    claimed_profit_cost: d("275.25"),
    claimed_travel_cost: d("12.00"),
    claimed_waiting_cost: d("8.50"),
    claimed_disbursement_cost: d("140.00"),
    allowed_profit_cost: d("250.00"),
    allowed_travel_cost: d("10.00"),
    allowed_waiting_cost: d("5.00"),
    allowed_disbursement_cost: d("100.00")
  )

  nsm4 = create_nsm(
    laa_reference: "LAA-0004",
    ufn: "040101/004",
    solicitor_office_code: "2B456C",
    stage_code: "PROM",
    client_first_name: "Diego",
    client_last_name: "Diaz"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_amendment",
    submitted_at: 18.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm4,
    claimed_profit_cost: d("510.00"),
    claimed_travel_cost: d("0.00"),
    claimed_waiting_cost: d("12.00"),
    claimed_disbursement_cost: d("60.00"),
    allowed_profit_cost: d("400.00"),
    allowed_travel_cost: d("0.00"),
    allowed_waiting_cost: d("10.00"),
    allowed_disbursement_cost: d("40.00")
  )

  nsm5 = create_nsm(
    laa_reference: "LAA-0005",
    ufn: "050101/005",
    solicitor_office_code: "3C789D",
    stage_code: "PROG",
    client_first_name: "Erin",
    client_last_name: "Evans"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_supplemental",
    submitted_at: 16.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm5,
    claimed_profit_cost: d("180.00"),
    claimed_travel_cost: d("18.00"),
    claimed_waiting_cost: d("6.00"),
    claimed_disbursement_cost: d("200.00"),
    allowed_profit_cost: d("150.00"),
    allowed_travel_cost: d("10.00"),
    allowed_waiting_cost: d("5.00"),
    allowed_disbursement_cost: d("150.00")
  )

  nsm6 = create_nsm(
    laa_reference: "LAA-0006",
    ufn: "060101/006",
    solicitor_office_code: "3C789D",
    stage_code: "PROM",
    client_first_name: "Farah",
    client_last_name: "Fisher"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_magistrate",
    submitted_at: 14.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm6,
    claimed_profit_cost: d("350.00"),
    claimed_travel_cost: d("22.50"),
    claimed_waiting_cost: d("9.00"),
    claimed_disbursement_cost: d("120.00"),
    allowed_profit_cost: d("300.00"),
    allowed_travel_cost: d("15.00"),
    allowed_waiting_cost: d("8.00"),
    allowed_disbursement_cost: d("100.00")
  )

  nsm7 = create_nsm(
    laa_reference: "LAA-0007",
    ufn: "070101/007",
    solicitor_office_code: "1A123B",
    stage_code: "PROG",
    client_first_name: "Greg",
    client_last_name: "Garcia"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_appeal",
    submitted_at: 13.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm7,
    claimed_profit_cost: d("260.00"),
    claimed_travel_cost: d("15.00"),
    claimed_waiting_cost: d("6.50"),
    claimed_disbursement_cost: d("110.00"),
    allowed_profit_cost: d("240.00"),
    allowed_travel_cost: d("10.00"),
    allowed_waiting_cost: d("5.00"),
    allowed_disbursement_cost: d("90.00")
  )

  nsm8 = create_nsm(
    laa_reference: "LAA-0008",
    ufn: "080101/008",
    solicitor_office_code: "2B456C",
    stage_code: "PROM",
    client_first_name: "Hiren",
    client_last_name: "Hughes"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_amendment",
    submitted_at: 12.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm8,
    claimed_profit_cost: d("495.00"),
    claimed_travel_cost: d("12.00"),
    claimed_waiting_cost: d("10.00"),
    claimed_disbursement_cost: d("75.00"),
    allowed_profit_cost: d("420.00"),
    allowed_travel_cost: d("10.00"),
    allowed_waiting_cost: d("8.00"),
    allowed_disbursement_cost: d("60.00")
  )

  nsm9 = create_nsm(
    laa_reference: "LAA-0009",
    ufn: "090101/009",
    solicitor_office_code: "3C789D",
    stage_code: "PROG",
    client_first_name: "Isla",
    client_last_name: "Irving"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_magistrate",
    submitted_at: 11.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm9,
    claimed_profit_cost: d("330.00"),
    claimed_travel_cost: d("20.00"),
    claimed_waiting_cost: d("9.00"),
    claimed_disbursement_cost: d("90.00"),
    allowed_profit_cost: d("300.00"),
    allowed_travel_cost: d("15.00"),
    allowed_waiting_cost: d("8.00"),
    allowed_disbursement_cost: d("70.00")
  )

  nsm10 = create_nsm(
    laa_reference: "LAA-0010",
    ufn: "100101/010",
    solicitor_office_code: "4D012E",
    stage_code: "PROM",
    client_first_name: "Jamie",
    client_last_name: "Jones"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_supplemental",
    submitted_at: 10.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm10,
    claimed_profit_cost: d("210.00"),
    claimed_travel_cost: d("10.00"),
    claimed_waiting_cost: d("6.00"),
    claimed_disbursement_cost: d("160.00"),
    allowed_profit_cost: d("180.00"),
    allowed_travel_cost: d("8.00"),
    allowed_waiting_cost: d("5.00"),
    allowed_disbursement_cost: d("140.00")
  )

  nsm11 = create_nsm(
    laa_reference: "LAA-0011",
    ufn: "110101/011",
    solicitor_office_code: "5E345F",
    stage_code: "PROG",
    client_first_name: "Kira",
    client_last_name: "Khan"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_mag_appeal",
    submitted_at: 9.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm11,
    claimed_profit_cost: d("285.00"),
    claimed_travel_cost: d("16.00"),
    claimed_waiting_cost: d("7.00"),
    claimed_disbursement_cost: d("130.00"),
    allowed_profit_cost: d("250.00"),
    allowed_travel_cost: d("12.00"),
    allowed_waiting_cost: d("6.00"),
    allowed_disbursement_cost: d("100.00")
  )

  nsm12 = create_nsm(
    laa_reference: "LAA-0012",
    ufn: "120101/012",
    solicitor_office_code: "1A123B",
    stage_code: "PROM",
    client_first_name: "Liam",
    client_last_name: "Lewis"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "non_standard_magistrate",
    submitted_at: 8.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: nsm12,
    claimed_profit_cost: d("365.00"),
    claimed_travel_cost: d("14.00"),
    claimed_waiting_cost: d("8.00"),
    claimed_disbursement_cost: d("115.00"),
    allowed_profit_cost: d("320.00"),
    allowed_travel_cost: d("10.00"),
    allowed_waiting_cost: d("7.00"),
    allowed_disbursement_cost: d("95.00")
  )

  # --------------------------------
  # ASSIGNED COUNSEL CLAIMS (8)
  # --------------------------------

  ac1 = create_ac(
    laa_reference: "LAA-1001",
    ufn: "130101/013",
    counsel_office_code: "1AB180F",
    solicitor_office_code: "4D012E",
    stage_code: "PROG",
    client_first_name: "Maya",
    client_last_name: "Murray"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel",
    submitted_at: 7.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac1,
    claimed_net_assigned_counsel_cost: d("800.00"),
    claimed_assigned_counsel_vat: d("160.00"),
    allowed_net_assigned_counsel_cost: d("650.00"),
    allowed_assigned_counsel_vat: d("130.00")
  )

  ac2 = create_ac(
    laa_reference: "LAA-1002",
    ufn: "140101/014",
    counsel_office_code: "2AB180F",
    solicitor_office_code: "4D012E",
    stage_code: "PROM",
    client_first_name: "Noah",
    client_last_name: "Novak"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel_appeal",
    submitted_at: 6.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac2,
    claimed_net_assigned_counsel_cost: d("950.00"),
    claimed_assigned_counsel_vat: d("190.00"),
    allowed_net_assigned_counsel_cost: d("800.00"),
    allowed_assigned_counsel_vat: d("160.00")
  )

  ac3 = create_ac(
    laa_reference: "LAA-1003",
    ufn: "150101/015",
    counsel_office_code: "3AB180F",
    solicitor_office_code: "5E345F",
    stage_code: "PROG",
    client_first_name: "Omar",
    client_last_name: "Oneill"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel_amendment",
    submitted_at: 5.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac3,
    claimed_net_assigned_counsel_cost: d("600.00"),
    claimed_assigned_counsel_vat: d("120.00"),
    allowed_net_assigned_counsel_cost: d("500.00"),
    allowed_assigned_counsel_vat: d("100.00")
  )

  ac4 = create_ac(
    laa_reference: "LAA-1004",
    ufn: "160101/016",
    counsel_office_code: "4AB180F",
    solicitor_office_code: "5E345F",
    stage_code: "PROM",
    client_first_name: "Priya",
    client_last_name: "Patel"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel",
    submitted_at: 4.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac4,
    claimed_net_assigned_counsel_cost: d("700.00"),
    claimed_assigned_counsel_vat: d("140.00"),
    allowed_net_assigned_counsel_cost: d("550.00"),
    allowed_assigned_counsel_vat: d("110.00")
  )

  ac5 = create_ac(
    laa_reference: "LAA-1005",
    ufn: "170101/017",
    counsel_office_code: "5AB180F",
    solicitor_office_code: "1A123B",
    stage_code: "PROG",
    client_first_name: "Quinn",
    client_last_name: "Quinn"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel_appeal",
    submitted_at: 3.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac5,
    claimed_net_assigned_counsel_cost: d("880.00"),
    claimed_assigned_counsel_vat: d("176.00"),
    allowed_net_assigned_counsel_cost: d("740.00"),
    allowed_assigned_counsel_vat: d("148.00")
  )

  ac6 = create_ac(
    laa_reference: "LAA-1006",
    ufn: "180101/018",
    counsel_office_code: "6AB180F",
    solicitor_office_code: "2B456C",
    stage_code: "PROM",
    client_first_name: "Rosa",
    client_last_name: "Reid"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel_amendment",
    submitted_at: 2.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac6,
    claimed_net_assigned_counsel_cost: d("640.00"),
    claimed_assigned_counsel_vat: d("128.00"),
    allowed_net_assigned_counsel_cost: d("520.00"),
    allowed_assigned_counsel_vat: d("104.00")
  )

  ac7 = create_ac(
    laa_reference: "LAA-1007",
    ufn: "190101/019",
    counsel_office_code: "7GE251B",
    solicitor_office_code: "3C789D",
    stage_code: "PROG",
    client_first_name: "Sam",
    client_last_name: "Singh"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel",
    submitted_at: 2.days.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac7,
    claimed_net_assigned_counsel_cost: d("720.00"),
    claimed_assigned_counsel_vat: d("144.00"),
    allowed_net_assigned_counsel_cost: d("580.00"),
    allowed_assigned_counsel_vat: d("116.00")
  )

  ac8 = create_ac(
    laa_reference: "LAA-1008",
    ufn: "200101/020",
    counsel_office_code: "8GE251B",
    solicitor_office_code: "4D012E",
    stage_code: "PROM",
    client_first_name: "Tara",
    client_last_name: "Turner"
  )

  create_payment_request(
    submitter_id: SecureRandom.uuid,
    request_type: "assigned_counsel",
    submitted_at: 1.day.ago,
    date_received: rand(1..5).days.ago,
    payment_request_claim: ac8,
    claimed_net_assigned_counsel_cost: d("670.00"),
    claimed_assigned_counsel_vat: d("134.00"),
    allowed_net_assigned_counsel_cost: d("540.00"),
    allowed_assigned_counsel_vat: d("108.00")
  )

end

puts "Seeded exactly 21 PaymentRequests (13 NSM, 8 Assigned Counsel)."
