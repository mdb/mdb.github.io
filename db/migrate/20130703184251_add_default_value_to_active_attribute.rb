class AddDefaultValueToActiveAttribute < ActiveRecord::Migration
  def change
    change_column :posts, :active, :boolean, :default => true
  end
end
