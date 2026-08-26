class DownloadRequestResource
  include Alba::Resource

  attributes :claim_id, :court_attendances, :court_name, :court_id, :no_of_defendants,
             :outcome_code, :office_name, :office_code, :stage_code, :ufn, :laa_reference,
             :work_completed_date, :original_submission_date, :youth_court, :client_last_name,
             :request_type, :allowed_disbursement_cost, :claimed_disbursement_cost,
             :allowed_profit_cost, :claimed_profit_cost, :allowed_travel_cost,
             :claimed_travel_cost, :allowed_waiting_cost, :claimed_waiting_cost,
             :claimed_total, :allowed_total, :date_received, :submitted_at

  def claim_id(payment_request)
    payment_request.payable_claim&.id
  end

  def court_attendances(payment_request)
    payment_request.payable_claim&.court_attendances
  end

  def court_name(payment_request)
    payment_request.payable_claim&.court_name
  end

  def court_id(payment_request)
    payment_request.payable_claim&.court_id
  end

  def no_of_defendants(payment_request)
    payment_request.payable_claim&.no_of_defendants
  end

  def outcome_code(payment_request)
    payment_request.payable_claim&.outcome_code
  end

  def office_name(payment_request)
    payment_request.payable_claim&.solicitor_firm_name
  end

  def office_code(payment_request)
    payment_request.payable_claim&.solicitor_office_code
  end

  def stage_code(payment_request)
    payment_request.payable_claim&.stage_code
  end

  def ufn(payment_request)
    payment_request.payable_claim&.ufn
  end

  def laa_reference(payment_request)
    payment_request.payable_claim&.laa_reference
  end

  def work_completed_date(payment_request)
    payment_request.payable_claim&.work_completed_date
  end

  def original_submission_date(payment_request)
    payment_request.payable_claim&.original_submission_date
  end

  def youth_court(payment_request)
    payment_request.payable_claim&.youth_court
  end

  def client_last_name(payment_request)
    payment_request.payable_claim&.client_last_name
  end

  def date_received(payment_request)
    payment_request.date_claim_assessed
  end
end
