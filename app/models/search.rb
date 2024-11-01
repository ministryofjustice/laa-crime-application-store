class Search < ApplicationRecord
  self.primary_key = :id
  belongs_to :submission, foreign_key: :application_id
  belongs_to :submission_version, foreign_key: :id, primary_key: :application_version_id

  # NOTE: This works due to splitting the search query via weights, with ufn and laa_reference
  # as weight A, then using simple reg-exp to determine which inputs should be queried on weight
  # A, and then everything else being only weight B.
  # This stops partial matches from being possible against the weight A values.
  def self.where_terms(string)
    return all unless string

    # Split each string into words by one-or-more whitespace characters
    sub_strings = string.strip.downcase.split(/\s+/).map do |str|
      # We escape with single quotes
      str = str.gsub("'", "''")

      # Is this an LAA reference or a UFN? (LAA-123ABC or 311223/001)
      if str.start_with?("laa-") || /\A\d+\/\d+\z/.match?(str) then %('''#{str}''':A)

      # Is this MAYBE a UFN? (6 digits for the first part, 9 digits for the full)
      elsif /\A\d{6}\z/.match?(str) then "#{str}:*"

      # Don't know what it is, but escape it anyway.
      # We've already checked for UFN and LAA reference, so we give it weight B
      else
        %('''#{str}''':*B)
      end
    end

    # The way the lexemes are setup in the search vector means a typical record ends up looking like
    #
    # '-123456':8A '010124/001':6A 'laa-123456':10A 'jason':2B 'jason/jim':1B 'jim':3B  'read':4B,5B
    #
    # In which we have the expected fields converted to lexemes, however in the case of the "Jason/Jim"
    # first name; we generate lexemes for both the full and partial matches of both names.
    #
    # We only do this for defendant name as caseworkers use that syntax for alternate names.
    where("searches.search_fields @@ to_tsquery('simple', ?)", sub_strings.compact.join(" & "))
  end
end
