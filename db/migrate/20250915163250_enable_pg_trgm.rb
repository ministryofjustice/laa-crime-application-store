class EnablePgTrgm < ActiveRecord::Migration[8.0]
  def change
    # extension needed for fuzzy matching string text
    enable_extension "pg_trgm"
  end
end
