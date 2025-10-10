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
      ActiveRecord::Base.transaction do
        payment_request = PaymentRequest.create!(
          request_type: params[:request_type],
          submitter_id: params[:submitter_id],
        )

        if params[:laa_reference].present?
          raise PaymentLinkError unless params[:request_type] == "non_standard_mag"

          ::PaymentRequests::LinkPayableService.call(payment_request, params)
        end
        render json: payment_request, status: :created
      end
    rescue ActiveRecord::RecordInvalid, PaymentLinkError => e
      render json: { errors: e.message }, status: :unprocessable_entity
    end

    def update
      ::PaymentRequests::UpdateService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid => e
      report_error(e)
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue ActiveRecord::RecordNotFound
      report_error(e)
      head :not_found
    end

    def link_payable
      ::PaymentRequests::LinkPayableService.call(current_payment_request, params)
      render json: current_payment_request, status: :created
    rescue ActiveRecord::RecordInvalid, PaymentLinkError => e
      report_error(e)
      render json: { errors: e.message }, status: :unprocessable_entity
    end

  private

    def index_params
      params.permit(:page)
    end

    def current_payment_request
      @current_payment_request ||= PaymentRequest.find(params[:id])
    end

    def authorization_object
      current_payment_request if action_name == "link_payable"
    end
  end
end
