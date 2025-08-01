module PaymentRequests
  class LinkPayableService
    class << self
      include LaaReferenceHelper

      def call(payment_request, params)
        claim = nil
        if params[:laa_reference].present?
          claim = find_referred_claim(params[:laa_reference])
        end

        case payment_request.request_type
        when "non_standard_mag"
          if params[:laa_reference].present?
            submission = find_referred_submission(params[:laa_reference])
            raise PaymentLinkError, I18n.t("errors.payment_request.no_ref_digital") if submission.nil?
            raise PaymentLinkError, I18n.t("errors.payment_request.invalid_link") unless submission.application_type == "crm7"

            application_data = submission.latest_version.application

            payment_request.payable = NsmClaim.create!(
              laa_reference: params[:laa_reference],
              submission: submission,
              ufn: application_data["ufn"],
              firm_name: application_data.dig("firm_office", "name"),
              office_code: application_data["office_code"],
              stage_code: application_data["stage_reached"],
              client_surname: submission.latest_version.main_defendant["last_name"],
              case_concluded_date: application_data["work_completed_date"],
              court_name: application_data["court"],
              court_attendances: application_data["number_of_hearing"],
              no_of_defendants: application_data["defendants"].count,
            )

            payment_request.update!(
              profit_cost: submission.latest_version.totals[:cost_summary][:profit_costs][:claimed_total_inc_vat],
              travel_cost: submission.latest_version.totals[:cost_summary][:travel][:claimed_total_inc_vat],
              waiting_cost: submission.latest_version.totals[:cost_summary][:waiting][:claimed_total_inc_vat],
              disbursement_cost: submission.latest_version.totals[:cost_summary][:disbursements][:claimed_total_inc_vat],
              allowed_profit_cost: submission.latest_version.totals[:cost_summary][:profit_costs][:assessed_total_inc_vat],
              allowed_travel_cost: submission.latest_version.totals[:cost_summary][:travel][:assessed_total_inc_vat],
              allowed_waiting_cost: submission.latest_version.totals[:cost_summary][:waiting][:assessed_total_inc_vat],
              allowed_disbursement_cost: submission.latest_version.totals[:cost_summary][:disbursements][:assessed_total_inc_vat],
            )
          else
            payment_request.payable = NsmClaim.create!(
              laa_reference: generate_laa_reference,
            )
          end
        when "non_standard_mag_supplemental", "non_standard_mag_amendment", "non_standard_mag_appeal"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_ref") if params[:laa_reference].blank?
          raise PaymentLinkError, I18n.t("errors.payment_request.does_not_exist") if claim.nil?

          payment_request.payable = claim
        when "assigned_counsel"
          if params[:laa_reference].blank?
            payment_request.payable = AssignedCounselClaim.create!(
              laa_reference: generate_laa_reference,
            )
          else
            raise PaymentLinkError, I18n.t("errors.payment_request.assigned_counsel_origin_wrong_ref") unless claim.is_a?(NsmClaim)

            payment_request.payable = AssignedCounselClaim.create!(
              laa_reference: generate_laa_reference,
              nsm_claim: claim,
            )
          end
        when "assigned_counsel_amendment", "assigned_counsel_appeal"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_ref") if params[:laa_reference].blank?
          raise PaymentLinkError, I18n.t("errors.payment_request.assigned_counsel_wrong_ref") unless claim.is_a?(AssignedCounselClaim)

          payment_request.payable = claim
        else
          raise PaymentLinkError, I18n.t("errors.payment_request.invalid_type")
        end

        raise PaymentLinkError, I18n.t("errors.payment_request.legacy_supplemental") if is_supplemental_claim?(claim)

        payment_request.save!
      end

      # rubocop:disable Style/SafeNavigationChainLength
      def is_supplemental_claim?(claim)
        return false unless claim.is_a?(NsmClaim)

        claim.submission&.latest_version&.application&.dig("supplemental_claim") == "yes"
      end
      # rubocop:enable Style/SafeNavigationChainLength
    end
  end
end
