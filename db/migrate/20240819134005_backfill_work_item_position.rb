class BackfillWorkItemPosition < ActiveRecord::Migration[7.1]

  disable_ddl_transaction!

  def up
    # We need to update NSM claims (only) with one or more nil/null work_item positions.
    #
    # These claims should have all their work_items position attributes updated to be a 1-based
    # index value when sorted by completed_on and work type. This sorting algorithm should match
    # what is used for newly submitted claims BUT should not "touch" any updated_at column values.
    #

    # OR submission version with any work_items
    # SubmissionVersion.where("application ->'work_items' IS NOT NULL")

    # claims = Submission.where(application_type: "crm7")

    # claims.each do |claim|
    #   claim.ordered_submission_versions.each do |sub_ver|
    #     updater = DataMigrationTools::WorkItemPositionUpdater.new(sub_ver)
    #     updater.call
    #   end
    # end
  end
end

