class AddProfileRow < ActiveRecord::Migration[5.0]
  def change
    add_column :rows, :profiles, :string
  end
end
