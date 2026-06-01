class UpdateSubmissionsByServicesToVersion6 < ActiveRecord::Migration[8.1]
  def change
    update_view :submission_by_services, version: 6, revert_to_version: 5
  end
end
