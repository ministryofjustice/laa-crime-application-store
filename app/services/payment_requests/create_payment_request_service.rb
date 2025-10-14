module PaymentRequests
  class CreatePaymentRequestService
    class UnprocessableEntityError < StandardError; end
    include LaaReferenceHelper

    attr_reader :params

    CLAIM_TYPE_MAP = {
      "NsmClaim" => %w[
        non_standard_mag
        non_standard_mag_supplemental
        non_standard_mag_appeal
        non_standard_mag_amendment
      ],
      "AssignedCounselClaim" => %w[
        assigned_counsel
        assigned_counsel_appeal
        assigned_counsel_amendment
      ],
    }.freeze

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
        firm_name: firm_name,
        office_code: params[:office_code],
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
        laa_reference: generate_laa_reference,
        ufn: params[:ufn],
        date_received: params[:date_received],
      }
    end

    def assigned_counsel_claim_details
      {
        solicitor_office_code: params[:solicitor_office_code],
        nsm_claim_id: params[:nsm_claim_id],
      }
    end

    def build_payment_request(claim)
      claim.payment_requests.build(
        submitter_id: params[:submitter_id],
        request_type: params[:request_type],
        submitted_at: Time.current,
        date_claim_received: params[:date_claim_received],
      )
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
        profit_cost: params[:claimed_profit_costs],
        travel_cost: params[:claimed_travel_costs],
        waiting_cost: params[:claimed_waiting_costs],
        disbursement_cost: params[:claimed_disbursement_costs],
        allowed_profit_cost: params[:allowed_profit_costs],
        allowed_travel_cost: params[:allowed_travel_costs],
        allowed_waiting_cost: params[:allowed_waiting_costs],
        allowed_disbursement_cost: params[:allowed_disbursement_costs],
        allowed_total: params[:total_allowed_costs],
        claimed_total: params[:total_claimed_costs],
      }
    end

    def mapped_assigned_counsel_cost_attributes
      {
        net_assigned_counsel_cost: params[:net_assigned_counsel_cost],
        assigned_counsel_vat: params[:assigned_counsel_vat],
        allowed_net_assigned_counsel_cost: params[:allowed_net_assigned_counsel_cost],
        allowed_assigned_counsel_vat: params[:allowed_assigned_counsel_vat],
      }
    end

    def firm_name
      "TODO"
    end

    def supplemental_appeal_or_ammendment?
      params[:request_type].end_with?("_supplemental", "_amendment", "_appeal")
    end

    def claim_type
      @claim_type ||= CLAIM_TYPE_MAP.find { |_, types| types.include?(params[:request_type]) }&.first
    end
  end
end
