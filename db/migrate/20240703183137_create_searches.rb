class CreateSearches < ActiveRecord::Migration[7.1]
  def change
    create_view :searches
  end
end
