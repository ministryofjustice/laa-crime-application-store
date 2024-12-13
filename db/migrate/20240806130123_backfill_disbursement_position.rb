
class BackfillDisbursementPosition < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # We need to update NSM claims (only) with one or more nil/null disbursement positions.
    #
    # These claims should have all their disbursements position attributes updated to be a 1-based
    # index value when sorted by disbursement_date and "translated disbursement type description". This
    # sorting algorithm should match what is used for newly submitted claims BUT should not "touch" any
    # updated_at column values.
    #

    # OR submission version with any disbursements
    # SubmissionVersion.where("application ->'disbursements' IS NOT NULL")

    # claims = Submission.where(application_type: "crm7")

    # claims.each do |claim|
    #   claim.ordered_submission_versions.each do |sub_ver|
    #     updater = DataMigrationTools::DisbursementPositionUpdater.new(sub_ver)
    #     updater.call
    #   end
    # end
  end
end
