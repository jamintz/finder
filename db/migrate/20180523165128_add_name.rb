class AddName < ActiveRecord::Migration[5.0]
  def change
    add_column :rows, :firstname, :string
    add_column :rows, :lastname, :string
    
  end
end
