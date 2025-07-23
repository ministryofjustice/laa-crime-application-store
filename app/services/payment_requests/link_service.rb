module PaymentRequests
  class LinkService
    include GenerateLaaReference

    class << self
      def call(payment_request, params)
        case payment_request.request_type

        when "non_standard_mag"
          if params[:laa_reference].present?
            raise_error PaymentLinkError t("errors.payment_requests.non_paper_nsm_link")
          else
            nsm_claim = NsmClaim.create!(
              laa_reference: generate_laa_reference,
            )
            payment_request.payable = nsm_claim
          end
        end
      end
    end
  end
end
