module V1
  class PaymentRequestClaimsController < ApplicationController
    def show
      render json: payment_request_claim_resource, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      report_error(e)
      head :not_found
    end

  private

    def payment_request_claim_resource
      payment_request_claim ||= PaymentRequestClaim.find(params[:id])

      @payment_request_claim_resource ||= PaymentRequestClaimResource.new(
        payment_request_claim, params: { include_claim: false }
      ).serialize
    end
  end
end
