
module Nsm
  class ClearImportErrorDetails < ApplicationJob
    sidekiq_options retry: 1

    def perform
      return false if filtered_records.empty?

      filtered_records.each do |record|
        record.details = nil
        record.save
      end
    end

    def filtered_records
      FailedImport.where(created_at: ..1.week.ago.end_of_day)
    end
  end
end
