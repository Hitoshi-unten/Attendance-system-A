class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :affiliation #所属
      t.integer :employee_number #社員番号
      t.string :uid #カードID

      t.timestamps
    end
  end
end
