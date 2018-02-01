class CompleteRow < ActiveRecord::Migration[5.0]
  def change
    add_column :rows, :checked, :boolean, :default => false
    add_column :rows, :unique, :boolean
  end
end
