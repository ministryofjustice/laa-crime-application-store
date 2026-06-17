class RemoveIndexesForSubmissionByService < ActiveRecord::Migration[8.1]
  def change
    %w[
      idx_application_version_service_type_pending
      idx_application_version_pending
    ].each do |index_name|
      remove_index :application_version, name: index_name, if_exists: true  
    end
  end
end
