class UpdateSubmissionByServicesToVersion4 < ActiveRecord::Migration[7.2]
  def change
    update_view :submission_by_services, version: 4, revert_to_version: 3
  end
end
