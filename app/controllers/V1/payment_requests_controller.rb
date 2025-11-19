module V1
  class PaymentRequestsController < ApplicationController
    def index
      payment_requests = ::PaymentRequests::SearchService.call(index_params, current_client_role)
      render json: payment_requests, status: :ok
    end

    def show
      payment_request_resource = PaymentRequestResource.new(current_payment_request, params: { include_claim: true }).serialize
      render json: payment_request_resource, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      report_error(e)
      head :not_found
    end

    def create
      payment_request_claim = ::PaymentRequests::CreatePaymentRequestService.new(params).call
      render json: payment_request_claim, status: :created
    rescue ActiveRecord::RecordInvalid, StandardError => e
      report_error(e)
      render json: { errors: e.message }, status: :unprocessable_content
    end

  private

    def index_params
      params.permit(:page)
    end

    def current_payment_request
      @current_payment_request ||= PaymentRequest.find(params[:id])
    end
  end
end
