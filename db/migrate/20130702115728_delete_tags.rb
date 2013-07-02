class DeleteTags < ActiveRecord::Migration
  def up
    drop_table :tags
  end

  def down
  end
end
