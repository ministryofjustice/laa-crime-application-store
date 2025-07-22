class ChangePaymentRequestTypeToRequestType < ActiveRecord::Migration[8.0]
  def change
    rename_column :payment_requests, :type, :request_type
  end
end
