module PaymentRequests
  class LinkService
    class << self
      include GenerateLaaReference

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
        end

        payment_request.save!
      end
    end
  end
end
