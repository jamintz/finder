class AddToRow < ActiveRecord::Migration[5.0]
  def change
    add_column :rows, :jobtitle, :string
    add_column :rows, :city, :string
    add_column :rows, :pro_path, :string
    
  end
end
