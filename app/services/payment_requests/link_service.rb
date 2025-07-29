module PaymentRequests
  class LinkService
    class << self
      include LaaReferenceHelper

      def call(payment_request, params)
        claim = nil
        if params[:laa_reference].present?
          claim = find_referred_claim(params[:laa_reference])
          raise PaymentLinkError, I18n.t("errors.payment_request.does_not_exist") if claim.nil?
          raise PaymentLinkError, I18n.t("errors.payment_request.legacy_supplemental") if is_supplemental_claim?(claim)
        end

        case payment_request.request_type
        when "non_standard_mag"
          if params[:laa_reference].present?
            raise PaymentLinkError, I18n.t("errors.payment_requests.non_paper_nsm_link")
          else
            payment_request.payable = NsmClaim.create!(
              laa_reference: generate_laa_reference,
            )
          end
        when "non_standard_mag_supplemental", "non_standard_mag_amendment", "non_standard_mag_appeal"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_ref") if params[:laa_reference].blank?

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
        # :nocov:
        else
          false
        end
        # :nocov:

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
