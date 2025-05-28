# https://dsdmoj.atlassian.net/browse/CRM457-2576
namespace :CRM457_2576 do
  desc "Backfill import_failed type"
  task backfill_import_failed_details: :environment do
    FailedImport.where(details: nil).update_all(error_type: "UNKNOWN")
  end
end
