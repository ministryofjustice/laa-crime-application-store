class AddNsmClaimTable < ActiveRecord::Migration[8.0]
  def change
    create_table :nsm_claims, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "laa_reference"
      t.string "ufn"
      t.datetime "date_received"
      t.string "firm_name"
      t.string "office_code"
      t.string "stage_code"
      t.string "client_surname"
      t.datetime "case_concluded_date"
      t.string "court_name"
      t.integer "court_attendances"
      t.integer "no_of_defendants"
      t.timestamps
    end
  end
end
