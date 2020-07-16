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
# rails g model Post content:text
# gはgenerateの省略。「postsテーブル」を作成する場合、「post」のように単数形で指定する。また、頭文字を大文字にして入力する。「カラム名：データ型」contentカラムをtext型で生成する指示を出している。