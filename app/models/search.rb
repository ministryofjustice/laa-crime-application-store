class Search < ApplicationRecord
  self.primary_key = :id
  belongs_to :submission, foreign_key: :application_id
  belongs_to :submission_version, foreign_key: :id, primary_key: :application_version_id

  def self.search(string)
    where("searches.search_fields @@ to_tsquery('simple', ?)", string).or(
      where("LOWER(searches.ufn) = LOWER(?)", string)
    ).or(
      where("LOWER(searches.laa_reference) = LOWER(?)", string)
    )
  end
end