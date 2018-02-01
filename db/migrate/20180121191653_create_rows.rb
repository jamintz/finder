class CreateRows < ActiveRecord::Migration[5.0]
  def change
    create_table :rows do |t|
      t.integer :batch_id
      t.string :name
      t.string :school
      t.string :business

      t.timestamps
    end
  end
end
