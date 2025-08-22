module PaymentRequests
  class LinkPayableService
    class << self
      include LaaReferenceHelper

      def call(payment_request, params)
        claim = nil
        if params[:laa_reference].present?
          claim = find_referred_claim(params[:laa_reference])
          submission = find_referred_submission(params[:laa_reference])
          raise PaymentLinkError, I18n.t("errors.payment_request.legacy_supplemental") if submission && is_supplemental?(submission)
        end

        case payment_request.request_type
        when "non_standard_mag"
          if params[:laa_reference].present?
            raise PaymentLinkError, I18n.t("errors.payment_request.no_ref_digital") if submission.nil?
            raise PaymentLinkError, I18n.t("errors.payment_request.invalid_link") unless submission.application_type == "crm7"

            application_data = submission.latest_version.application
            claim = Presenters::V1::Nsm::Claim.new(submission)

            payment_request.nsm_claim = NsmClaim.create!(
              laa_reference: params[:laa_reference],
              submission: submission,
              ufn: application_data["ufn"],
              firm_name: application_data.dig("firm_office", "name"),
              office_code: application_data["office_code"],
              stage_code: application_data["stage_reached"],
              client_first_name: claim.main_defendant["first_name"],
              client_last_name: claim.main_defendant["last_name"],
              work_completed_date: application_data["work_completed_date"],
              youth_court: application_data["youth_court"],
              matter_type: application_data["matter_type"],
              outcome_code: application_data["hearing_outcome"],
              court_name: application_data["court"],
              court_attendances: application_data["number_of_hearing"],
              no_of_defendants: application_data["defendants"].count,
            )

            payment_request.update!(
              profit_cost: claim.totals[:cost_summary][:profit_costs][:claimed_total_inc_vat],
              travel_cost: claim.totals[:cost_summary][:travel][:claimed_total_inc_vat],
              waiting_cost: claim.totals[:cost_summary][:waiting][:claimed_total_inc_vat],
              disbursement_cost: claim.totals[:cost_summary][:disbursements][:claimed_total_inc_vat],
              allowed_profit_cost: claim.totals[:cost_summary][:profit_costs][:assessed_total_inc_vat],
              allowed_travel_cost: claim.totals[:cost_summary][:travel][:assessed_total_inc_vat],
              allowed_waiting_cost: claim.totals[:cost_summary][:waiting][:assessed_total_inc_vat],
              allowed_disbursement_cost: claim.totals[:cost_summary][:disbursements][:assessed_total_inc_vat],
            )
          else
            payment_request.nsm_claim = NsmClaim.create!(
              laa_reference: generate_laa_reference,
            )
          end
        when "non_standard_mag_supplemental", "non_standard_mag_amendment", "non_standard_mag_appeal"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_ref") if params[:laa_reference].blank?
          raise PaymentLinkError, I18n.t("errors.payment_request.does_not_exist") if claim.nil?

          payment_request.payment_request_claim = claim
        when "assigned_counsel"
          if params[:laa_reference].blank?
            payment_request.assigned_counsel_claim = AssignedCounselClaim.create!(
              laa_reference: generate_laa_reference,
            )
          else
            raise PaymentLinkError, I18n.t("errors.payment_request.assigned_counsel_origin_wrong_ref") unless claim.is_a?(NsmClaim)

            payment_request.assigned_counsel_claim = AssignedCounselClaim.create!(
              laa_reference: generate_laa_reference,
              nsm_claim: claim,
            )
          end
        when "assigned_counsel_amendment", "assigned_counsel_appeal"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_ref") if params[:laa_reference].blank?
          raise PaymentLinkError, I18n.t("errors.payment_request.assigned_counsel_wrong_ref") unless claim.is_a?(AssignedCounselClaim)

          payment_request.payment_request_claim = claim
        else
          raise PaymentLinkError, I18n.t("errors.payment_request.invalid_type")
        end

        payment_request.save!
      end

      def is_supplemental?(submission)
        submission.latest_version.application["supplemental_claim"] == "yes"
      end
    end
  end
end
