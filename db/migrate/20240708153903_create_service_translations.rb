require 'csv'

class CreateServiceTranslations < ActiveRecord::Migration[7.1]
  def change
    create_table :translations do |t|
      t.string :key
      t.string :translation
      t.string :translation_type
      t.timestamps
    end

    add_index :translations, [:key, :translation_type], unique: true

    Translation.upsert_all(translations, unique_by: [:key, :translation_type])
  end

  def translations
    file_name = Rails.root.join('db/migrate/20240708153903_service_translations.csv')
    translations = CSV.read(file_name, headers: true).map { _1.to_h }
    translations.each do |translation|
      translation['translation_type'] = 'service'
    end
  end
end
