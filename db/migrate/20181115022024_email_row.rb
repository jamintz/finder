class EmailRow < ActiveRecord::Migration[5.0]
  def change
    add_column :rows, :email_row, :string
  end
end
