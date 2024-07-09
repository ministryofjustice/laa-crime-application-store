require 'csv'

def translations
  file_name = Rails.root.join('db/migrate/20240708153903_service_translations.csv')
  translations = CSV.read(file_name, headers: true).map { _1.to_h }
  translations.each do |translation|
    translation['translation_type'] = 'service'
  end
end

Translation.upsert_all(translations, unique_by: [:key, :translation_type])
