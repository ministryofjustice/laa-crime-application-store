require 'csv'

class CreateServiceTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :service_translations do |t|
      t.string :key
      t.string :translation
      t.timestamps
    end

    add_index :service_translations, :key, unique: true

    ServiceTranslation.upsert_all(translations, unique_by: :key)
  end

  def translations
    file_name = Rails.root.join('db/migrate/20240708153903_service_translations.csv')
    limits = CSV.read(file_name, headers: true).map { _1.to_h }
  end
end
