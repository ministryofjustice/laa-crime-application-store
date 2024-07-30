class CreateActiveProviders < ActiveRecord::Migration[7.1]
  def change
    create_view :active_providers
  end
end
