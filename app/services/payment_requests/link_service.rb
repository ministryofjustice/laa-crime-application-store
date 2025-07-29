module PaymentRequests
  class LinkService
    class << self
      include LaaReference

      def call(payment_request, params)
        case payment_request.request_type

        when "non_standard_mag"
          if params[:laa_reference].present?
            raise PaymentLinkError, I18n.t("errors.payment_requests.non_paper_nsm_link")
          else
            payment_request.payable = NsmClaim.create!(
              laa_reference: generate_laa_reference,
            )
          end
        when "non_standard_mag_supplemental"
          raise PaymentLinkError, I18n.t("errors.payment_request.no_supplemental_ref") if params[:laa_reference].blank?

          claim = find_referred_claim(params[:laa_reference])
          raise PaymentLinkError, I18n.t("errors.payment_request.does_not_exist") if claim.nil?

          payment_request.payable = claim
        end

        payment_request.save!
      end
    end
  end
end
