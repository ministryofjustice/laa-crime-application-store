class AddAssignedCounselClaimTable < ActiveRecord::Migration[8.0]
  def change
    create_table :assigned_counsel_claims, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "laa_reference"
      t.string "counsel_office_code"
      t.timestamps
    end
  end
end
