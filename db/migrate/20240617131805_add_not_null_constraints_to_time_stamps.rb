class AddNotNullConstraintsToTimeStamps < ActiveRecord::Migration[7.1]
  # Reference: https://github.com/ankane/strong_migrations?tab=readme-ov-file#good-14
  def change
    add_check_constraint :application, "updated_at IS NOT NULL", name: "application_updated_at_null", validate: false
    add_check_constraint :application, "created_at IS NOT NULL", name: "application_created_at_null", validate: false
  end
end
