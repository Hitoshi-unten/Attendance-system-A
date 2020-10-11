class CreateBases < ActiveRecord::Migration[5.1]
  def change
    create_table :bases do |t|
      t.integer :base_id
      t.string :name
      t.string :attendance
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
