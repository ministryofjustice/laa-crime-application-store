class AddFailedImports < ActiveRecord::Migration[8.0]
  def change
    create_table :failed_imports, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "provider_id", null: false
      t.string "details"
      t.timestamps
    end
  end
end
