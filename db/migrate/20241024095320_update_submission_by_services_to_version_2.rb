class UpdateSubmissionByServicesToVersion2 < ActiveRecord::Migration[7.2]
  def change
    update_view :submission_by_services, version: 2, revert_to_version: 1
  end
end
