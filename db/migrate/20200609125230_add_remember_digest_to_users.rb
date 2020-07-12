class AddRememberDigestToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :remember_digest, :string
  end
end

#ログイン情報を残すカラム。残しておいたほうがいい。password_digestは残しておいてほうがいい。
#passwordは作る必要はない。password_digestに変換されるから。