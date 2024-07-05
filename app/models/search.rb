class Search < ApplicationRecord
  self.primary_key = :id
  belongs_to :submission, foreign_key: :application_id
  belongs_to :submission_version, foreign_key: :id, primary_key: :application_version_id

  # NOTE: This works due to splitting the search query via weights, with ufn and laa_reference
  # as weight A, then using simple reg-exp to determine which inputs should be queried on weight
  # A, and then everything else being only weight B.
  # This stops partial matches from being possible against the weight A values.
  def self.search(string)
    sub_strings = string.downcase.split(/\s+/).map do |str|
      if str =~ /\Alaa-/
        clean_str = str.sub(/\Alaa-/, 'laa')
        "#{clean_str}:A"
      elsif str =~ /\A\d+\/\d+\z/ then "#{str}:A"
      elsif str.blank? then nil
      else "#{str}:*B"
      end
    end

    where("searches.search_fields @@ to_tsquery('simple', ?)", sub_strings.compact.join(" & "))
  end
end
