module V1
  class PaymentRequestClaimsController < ApplicationController
    def show
      payment_request_claim_resource = PaymentRequestClaimResource.new(
        current_payment_request_claim, params: { include_claim: false }
      ).serialize
      render json: payment_request_claim_resource, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      report_error(e)
      head :not_found
    end

  private

    def current_payment_request_claim
      @current_payment_request_claim ||= PaymentRequestClaim.find(params[:id])
    end
  end
end
