module PaymentRequests
  class CreatePaymentRequestService
    class UnprocessableEntityError < StandardError; end
    include LaaReferenceHelper
    include ClaimTypeGroupHelper

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        claim = find_or_create_claim!
        raise UnprocessableEntityError, "Unable to determine claim type" unless claim

        payment_request = build_payment_request(claim)
        assign_costs(payment_request)
        unless payment_request.save
          raise UnprocessableEntityError, payment_request.errors.full_messages.to_sentence
        end

        { claim:, payment_request: }
      end
    rescue ActiveRecord::RecordInvalid => e
      raise UnprocessableEntityError, e.message
    end

  private

    def find_or_create_claim!
      if PaymentRequestClaim.exists?(idempotency_token: params[:idempotency_token])
        raise UnprocessableEntityError, "payment already exists: #{params[:idempotency_token]}"
      end

      if params[:laa_reference].present? && supplemental_appeal_or_ammendment?
        PaymentRequestClaim.find_by(laa_reference: params[:laa_reference]) || raise(UnprocessableEntityError, "Claim not found")
      else
        case claim_type
        when "NsmClaim"
          NsmClaim.create!(**nsm_claim_details)
        when "AssignedCounselClaim"
          AssignedCounselClaim.create!(**assigned_counsel_claim_details)
        else
          raise UnprocessableEntityError, "Unknown claim type: #{params[:request_type]}"
        end
      end
    end

    def nsm_claim_details
      {
        solicitor_firm_name: params[:solicitor_firm_name],
        solicitor_office_code: params[:solicitor_office_code],
        stage_code: params[:stage_reached],
        work_completed_date: params[:date_completed],
        court_attendances: params[:number_of_attendances],
        no_of_defendants: params[:number_of_defendants],
        client_first_name: params[:defendant_first_name],
        client_last_name: params[:defendant_last_name],
        outcome_code: params[:hearing_outcome_code],
        matter_type: params[:matter_type],
        court_name: params[:court],
        youth_court: params[:youth_court],
        laa_reference: params[:linked_laa_reference] || generate_laa_reference,
        ufn: params[:ufn],
        idempotency_token: params[:idempotency_token]
      }
    end

    def assigned_counsel_claim_details
      {
        counsel_office_code: params[:counsel_office_code],
        counsel_firm_name: params[:counsel_firm_name],
        solicitor_office_code: params[:solicitor_office_code],
        solicitor_firm_name: params[:solicitor_firm_name],
        client_last_name: params[:defendant_last_name],
        nsm_claim_id: params[:nsm_claim_id],
        ufn: params[:ufn],
        laa_reference: generate_laa_reference,
        idempotency_token: params[:idempotency_token]
      }
    end

    def build_payment_request(claim)
      payment_request = claim.payment_requests.build(
        submitter_id: params[:submitter_id],
        request_type: params[:request_type],
        submitted_at: Time.current,
        date_received: params[:date_received]
      )
      payment_request.submission_id = params[:id] if params[:linked_laa_reference]
      payment_request
    end

    def assign_costs(payment_request)
      case claim_type
      when "NsmClaim"
        payment_request.assign_attributes(mapped_nsm_cost_attributes)
      when "AssignedCounselClaim"
        payment_request.assign_attributes(mapped_assigned_counsel_cost_attributes)
      end
    end

    def mapped_nsm_cost_attributes
      {
        claimed_profit_cost: params[:claimed_profit_cost],
        claimed_travel_cost: params[:claimed_travel_cost],
        claimed_waiting_cost: params[:claimed_waiting_cost],
        claimed_disbursement_cost: params[:claimed_disbursement_cost],
        allowed_profit_cost: params[:allowed_profit_cost],
        allowed_travel_cost: params[:allowed_travel_cost],
        allowed_waiting_cost: params[:allowed_waiting_cost],
        allowed_disbursement_cost: params[:allowed_disbursement_cost],
        allowed_total: params[:allowed_total],
        claimed_total: params[:claimed_total],
      }
    end

    def mapped_assigned_counsel_cost_attributes
      {
        claimed_net_assigned_counsel_cost: params[:claimed_net_assigned_counsel_cost],
        claimed_assigned_counsel_vat: params[:claimed_assigned_counsel_vat],
        allowed_net_assigned_counsel_cost: params[:allowed_net_assigned_counsel_cost],
        allowed_assigned_counsel_vat: params[:allowed_assigned_counsel_vat],
        allowed_total: params[:allowed_total],
        claimed_total: params[:claimed_total],
      }
    end

    def supplemental_appeal_or_ammendment?
      params[:request_type].end_with?("_supplemental", "_amendment", "_appeal")
    end

    def claim_type
      @claim_type ||= find_claim_type_group(params[:request_type])
    end
  end
end
