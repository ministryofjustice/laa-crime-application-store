class CreateAdditionalFeeUptakes < ActiveRecord::Migration[8.0]
  def change
    create_view :additional_fee_uptakes
  end
end
