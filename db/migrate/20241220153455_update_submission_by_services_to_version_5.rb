class UpdateSubmissionByServicesToVersion5 < ActiveRecord::Migration[8.0]
  def change
    update_view :submission_by_services, version: 5, revert_to_version: 4
  end
end
