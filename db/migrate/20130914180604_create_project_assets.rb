class CreateProjectAssets < ActiveRecord::Migration
  def change
    create_table :project_assets do |t|
      t.string :project_asset_file_name
      t.string :project_asset_file_type
      t.integer :project_asset_file_size
      t.datetime :project_asset_updated_at
      t.integer :project_id

      t.timestamps
    end
  end
end
