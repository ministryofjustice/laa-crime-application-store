require "securerandom"
require "bigdecimal"

raise "payment seeds are dev-only (#{Rails.env})" unless Rails.env.development?

def d(num) = BigDecimal(num)

puts "== Wiping existing data =="
ActiveRecord::Base.transaction do
  PaymentRequest.destroy_all
  PaymentRequestClaim.destroy_all
end
puts "Wipe complete."

puts "== Reseeding 20 linked PaymentRequests =="

ActiveRecord::Base.transaction do
  # -------------------------
  # 12 NSM claims + requests
  # -------------------------
  nsm1 = NsmClaim.create!(laa_reference: "LAA-0001", ufn: "123456/101", office_code: "1A123B", stage_code: "PROG", client_first_name: "Ava", client_last_name: "Andrews", date_received: 30.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag", submitted_at: 25.days.ago, date_claim_received: nsm1.date_received, payment_request_claim: nsm1,
    profit_cost: d("300.40"), travel_cost: d("20.55"), waiting_cost: d("10.33"), disbursement_cost: d("100.00"),
    allowed_profit_cost: d("250.40"), allowed_travel_cost: d("0.00"), allowed_waiting_cost: d("6.40"), allowed_disbursement_cost: d("50.00"))

  nsm2 = NsmClaim.create!(laa_reference: "LAA-0002", ufn: "123457/102", office_code: "1A123B", stage_code: "PROM", client_first_name: "Ben", client_last_name: "Blake",   date_received: 28.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag", submitted_at: 22.days.ago, date_claim_received: nsm2.date_received, payment_request_claim: nsm2,
    profit_cost: d("420.00"), travel_cost: d("35.00"), waiting_cost: d("0.00"), disbursement_cost: d("80.00"),
    allowed_profit_cost: d("380.00"), allowed_travel_cost: d("20.00"), allowed_waiting_cost: d("0.00"), allowed_disbursement_cost: d("60.00"))

  nsm3 = NsmClaim.create!(laa_reference: "LAA-0003", ufn: "123458/103", office_code: "2B456C", stage_code: "PROG", client_first_name: "Carla", client_last_name: "Carter",  date_received: 26.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_appeal", submitted_at: 20.days.ago, date_claim_received: nsm3.date_received, payment_request_claim: nsm3,
    profit_cost: d("275.25"), travel_cost: d("12.00"), waiting_cost: d("8.50"), disbursement_cost: d("140.00"),
    allowed_profit_cost: d("250.00"), allowed_travel_cost: d("10.00"), allowed_waiting_cost: d("5.00"), allowed_disbursement_cost: d("100.00"))

  nsm4 = NsmClaim.create!(laa_reference: "LAA-0004", ufn: "123459/104", office_code: "2B456C", stage_code: "PROM", client_first_name: "Diego",  client_last_name: "Diaz",    date_received: 24.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_amendment", submitted_at: 18.days.ago, date_claim_received: nsm4.date_received, payment_request_claim: nsm4,
    profit_cost: d("510.00"), travel_cost: d("0.00"), waiting_cost: d("12.00"), disbursement_cost: d("60.00"),
    allowed_profit_cost: d("400.00"), allowed_travel_cost: d("0.00"), allowed_waiting_cost: d("10.00"), allowed_disbursement_cost: d("40.00"))

  nsm5 = NsmClaim.create!(laa_reference: "LAA-0005", ufn: "123460/105", office_code: "3C789D", stage_code: "PROG", client_first_name: "Erin",   client_last_name: "Evans",   date_received: 22.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_supplemental", submitted_at: 16.days.ago, date_claim_received: nsm5.date_received, payment_request_claim: nsm5,
    profit_cost: d("180.00"), travel_cost: d("18.00"), waiting_cost: d("6.00"), disbursement_cost: d("200.00"),
    allowed_profit_cost: d("150.00"), allowed_travel_cost: d("10.00"), allowed_waiting_cost: d("5.00"), allowed_disbursement_cost: d("150.00"))

  nsm6 = NsmClaim.create!(laa_reference: "LAA-0006", ufn: "123461/106", office_code: "3C789D", stage_code: "PROM", client_first_name: "Farah",  client_last_name: "Fisher",  date_received: 20.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag", submitted_at: 14.days.ago, date_claim_received: nsm6.date_received, payment_request_claim: nsm6,
    profit_cost: d("350.00"), travel_cost: d("22.50"), waiting_cost: d("9.00"), disbursement_cost: d("120.00"),
    allowed_profit_cost: d("300.00"), allowed_travel_cost: d("15.00"), allowed_waiting_cost: d("8.00"), allowed_disbursement_cost: d("100.00"))

  nsm7 = NsmClaim.create!(laa_reference: "LAA-0007", ufn: "123462/107", office_code: "1A123B", stage_code: "PROG", client_first_name: "Greg",   client_last_name: "Garcia",  date_received: 19.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_appeal", submitted_at: 13.days.ago, date_claim_received: nsm7.date_received, payment_request_claim: nsm7,
    profit_cost: d("260.00"), travel_cost: d("15.00"), waiting_cost: d("6.50"), disbursement_cost: d("110.00"),
    allowed_profit_cost: d("240.00"), allowed_travel_cost: d("10.00"), allowed_waiting_cost: d("5.00"), allowed_disbursement_cost: d("90.00"))

  nsm8 = NsmClaim.create!(laa_reference: "LAA-0008", ufn: "123463/108", office_code: "2B456C", stage_code: "PROM", client_first_name: "Hiren",  client_last_name: "Hughes",  date_received: 18.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_amendment", submitted_at: 12.days.ago, date_claim_received: nsm8.date_received, payment_request_claim: nsm8,
    profit_cost: d("495.00"), travel_cost: d("12.00"), waiting_cost: d("10.00"), disbursement_cost: d("75.00"),
    allowed_profit_cost: d("420.00"), allowed_travel_cost: d("10.00"), allowed_waiting_cost: d("8.00"), allowed_disbursement_cost: d("60.00"))

  nsm9 = NsmClaim.create!(laa_reference: "LAA-0009", ufn: "123464/109", office_code: "3C789D", stage_code: "PROG", client_first_name: "Isla",   client_last_name: "Irving",  date_received: 17.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag", submitted_at: 11.days.ago, date_claim_received: nsm9.date_received, payment_request_claim: nsm9,
    profit_cost: d("330.00"), travel_cost: d("20.00"), waiting_cost: d("9.00"), disbursement_cost: d("90.00"),
    allowed_profit_cost: d("300.00"), allowed_travel_cost: d("15.00"), allowed_waiting_cost: d("8.00"), allowed_disbursement_cost: d("70.00"))

  nsm10 = NsmClaim.create!(laa_reference: "LAA-0010", ufn: "123465/110", office_code: "4D012E", stage_code: "PROM", client_first_name: "Jamie", client_last_name: "Jones",   date_received: 16.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_supplemental", submitted_at: 10.days.ago, date_claim_received: nsm10.date_received, payment_request_claim: nsm10,
    profit_cost: d("210.00"), travel_cost: d("10.00"), waiting_cost: d("6.00"), disbursement_cost: d("160.00"),
    allowed_profit_cost: d("180.00"), allowed_travel_cost: d("8.00"), allowed_waiting_cost: d("5.00"), allowed_disbursement_cost: d("140.00"))

  nsm11 = NsmClaim.create!(laa_reference: "LAA-0011", ufn: "123466/111", office_code: "5E345F", stage_code: "PROG", client_first_name: "Kira",  client_last_name: "Khan",    date_received: 15.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag_appeal", submitted_at: 9.days.ago, date_claim_received: nsm11.date_received, payment_request_claim: nsm11,
    profit_cost: d("285.00"), travel_cost: d("16.00"), waiting_cost: d("7.00"), disbursement_cost: d("130.00"),
    allowed_profit_cost: d("250.00"), allowed_travel_cost: d("12.00"), allowed_waiting_cost: d("6.00"), allowed_disbursement_cost: d("100.00"))

  nsm12 = NsmClaim.create!(laa_reference: "LAA-0012", ufn: "123467/112", office_code: "1A123B", stage_code: "PROM", client_first_name: "Liam",  client_last_name: "Lewis",   date_received: 14.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "non_standard_mag", submitted_at: 8.days.ago, date_claim_received: nsm12.date_received, payment_request_claim: nsm12,
    profit_cost: d("365.00"), travel_cost: d("14.00"), waiting_cost: d("8.00"), disbursement_cost: d("115.00"),
    allowed_profit_cost: d("320.00"), allowed_travel_cost: d("10.00"), allowed_waiting_cost: d("7.00"), allowed_disbursement_cost: d("95.00"))

  # --------------------------------
  # 8 Assigned Counsel claims + reqs
  # --------------------------------
  ac1 = AssignedCounselClaim.create!(laa_reference: "LAA-1001", ufn: "223456/201", office_code: "4D012E", stage_code: "PROG", client_first_name: "Maya",   client_last_name: "Murray",   date_received: 13.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel", submitted_at: 7.days.ago, date_claim_received: ac1.date_received, payment_request_claim: ac1,
    net_assigned_counsel_cost: d("800.00"), assigned_counsel_vat: d("160.00"),
    allowed_net_assigned_counsel_cost: d("650.00"), allowed_assigned_counsel_vat: d("130.00"))

  ac2 = AssignedCounselClaim.create!(laa_reference: "LAA-1002", ufn: "223457/202", office_code: "4D012E", stage_code: "PROM", client_first_name: "Noah",   client_last_name: "Novak",    date_received: 12.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel_appeal", submitted_at: 6.days.ago, date_claim_received: ac2.date_received, payment_request_claim: ac2,
    net_assigned_counsel_cost: d("950.00"), assigned_counsel_vat: d("190.00"),
    allowed_net_assigned_counsel_cost: d("800.00"), allowed_assigned_counsel_vat: d("160.00"))

  ac3 = AssignedCounselClaim.create!(laa_reference: "LAA-1003", ufn: "223458/203", office_code: "5E345F", stage_code: "PROG", client_first_name: "Omar",   client_last_name: "Oneill",   date_received: 11.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel_amendment", submitted_at: 5.days.ago, date_claim_received: ac3.date_received, payment_request_claim: ac3,
    net_assigned_counsel_cost: d("600.00"), assigned_counsel_vat: d("120.00"),
    allowed_net_assigned_counsel_cost: d("500.00"), allowed_assigned_counsel_vat: d("100.00"))

  ac4 = AssignedCounselClaim.create!(laa_reference: "LAA-1004", ufn: "223459/204", office_code: "5E345F", stage_code: "PROM", client_first_name: "Priya",  client_last_name: "Patel",    date_received: 10.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel", submitted_at: 4.days.ago, date_claim_received: ac4.date_received, payment_request_claim: ac4,
    net_assigned_counsel_cost: d("700.00"), assigned_counsel_vat: d("140.00"),
    allowed_net_assigned_counsel_cost: d("550.00"), allowed_assigned_counsel_vat: d("110.00"))

  ac5 = AssignedCounselClaim.create!(laa_reference: "LAA-1005", ufn: "223460/205", office_code: "1A123B", stage_code: "PROG", client_first_name: "Quinn",  client_last_name: "Quinn",    date_received: 9.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel_appeal", submitted_at: 3.days.ago, date_claim_received: ac5.date_received, payment_request_claim: ac5,
    net_assigned_counsel_cost: d("880.00"), assigned_counsel_vat: d("176.00"),
    allowed_net_assigned_counsel_cost: d("740.00"), allowed_assigned_counsel_vat: d("148.00"))

  ac6 = AssignedCounselClaim.create!(laa_reference: "LAA-1006", ufn: "223461/206", office_code: "2B456C", stage_code: "PROM", client_first_name: "Rosa",   client_last_name: "Reid",     date_received: 8.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel_amendment", submitted_at: 2.days.ago, date_claim_received: ac6.date_received, payment_request_claim: ac6,
    net_assigned_counsel_cost: d("640.00"), assigned_counsel_vat: d("128.00"),
    allowed_net_assigned_counsel_cost: d("520.00"), allowed_assigned_counsel_vat: d("104.00"))

  ac7 = AssignedCounselClaim.create!(laa_reference: "LAA-1007", ufn: "223462/207", office_code: "3C789D", stage_code: "PROG", client_first_name: "Sam",    client_last_name: "Singh",    date_received: 7.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel", submitted_at: 2.days.ago, date_claim_received: ac7.date_received, payment_request_claim: ac7,
    net_assigned_counsel_cost: d("720.00"), assigned_counsel_vat: d("144.00"),
    allowed_net_assigned_counsel_cost: d("580.00"), allowed_assigned_counsel_vat: d("116.00"))

  ac8 = AssignedCounselClaim.create!(laa_reference: "LAA-1008", ufn: "223463/208", office_code: "4D012E", stage_code: "PROM", client_first_name: "Tara",   client_last_name: "Turner",   date_received: 6.days.ago)
  PaymentRequest.create!(submitter_id: SecureRandom.uuid, request_type: "assigned_counsel", submitted_at: 1.day.ago, date_claim_received: ac8.date_received, payment_request_claim: ac8,
    net_assigned_counsel_cost: d("670.00"), assigned_counsel_vat: d("134.00"),
    allowed_net_assigned_counsel_cost: d("540.00"), allowed_assigned_counsel_vat: d("108.00"))
end

puts "Seeded exactly 20 PaymentRequests (12 NSM, 8 Assigned Counsel)."
