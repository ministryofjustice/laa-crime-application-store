class AddErrorTypeToFailedImports < ActiveRecord::Migration[8.0]
  def change
    add_column :failed_imports, :error_type, :string
  end
end
