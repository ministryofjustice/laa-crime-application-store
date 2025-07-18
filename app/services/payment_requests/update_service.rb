module PaymentRequests
  class UpdateService
    class << self
      def call(payment_request, params)
        payment_request.with_lock do
          attributes_to_assign = {}

          case payment_request.payable_type
          when "NsmClaim"
            attributes_to_assign = {
              profit_cost: params[:profit_cost],
              travel_cost: params[:travel_cost],
              waiting_cost: params[:waiting_cost],
              disbursement_cost: params[:disbursement_cost],
              disbursement_vat: params[:disbursment_vat],
              allowed_profit_cost: params[:allowed_profit_cost],
              allowed_travel_cost: params[:allowed_travel_cost],
              allowed_waiting_cost: params[:allowed_waiting_cost],
              allowed_disbursement_cost: params[:allowed_disbursement_cost],
              allowed_disbursement_vat: params[:allowed_disbursment_vat],
            }
          when "AssignedCounselClaim"
            payment_request.assign_attributes(
              assigned_counsel_cost: params[:assigned_counsel_cost],
              assigned_counsel_vat: params[:assigned_counsel_vat],
              allowed_assigned_counsel_cost: params[:allowed_assigned_counsel_cost],
              allowed_assigned_counsel_vat: params[:allowed_assigned_counsel_cost],
            )
          end
          attributes_to_assign[:submitted_at] = Time.zone.local(params[:submitted_at])
          payment_request.assign_attributes(attributes_to_assign)
          payment_request.save!
        end
      end
    end
  end
end
