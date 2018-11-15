class EditName < ActiveRecord::Migration[5.0]
  def change
    rename_column :rows, :email_row, :email
  end
end
