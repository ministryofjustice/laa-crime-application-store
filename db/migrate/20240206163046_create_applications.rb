class CreateApplications < ActiveRecord::Migration[7.0]
  def change
    create_table :submissions do |t|
      t.string :application_id
      t.string :application_state
      t.string :application_risk
      t.string :application_type
      t.jsonb :events, default: []

      t.timestamps
    end

    create_table :submission_versions do |t|
      t.references :submission, foreign_key: true
      t.jsonb :data
      t.integer :json_schema_version

      t.timestamps
    end
  end
end
