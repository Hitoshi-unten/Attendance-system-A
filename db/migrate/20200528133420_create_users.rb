class CreateUsers < ActiveRecord::Migration[5.1]
# ファイルにはこれしか書かれていないが、このCreateUsersクラスがActiveRecord::Migration[5.1]クラスを継承していることに注目。これによって基本的なデータベースCRUD (Create、Read、Update、Destroy) 操作やデータのバリデーション（検証: validation）のほか、洗練された検索機能や複数のモデルを互いに関連付ける機能(リレーションシップ) など、きわめて多くの機能をRailsモデルに無償で提供している。
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
# rails generate modelを実行すると、データベースマイグレーションファイルがdb/migrateの下に作成される。マイグレーションはRubyのクラスであり、データベーステーブルの作成や変更を簡単に行うためのしくみ。マイグレーションを実行するにはコマンドを実行する。マイグレーションで行ったデータベース構成の変更は、後から取り消すことができる。マイグレーションファイルの名前にはタイムスタンプが含まれており、これに基いて、マイグレーションは作成された順に実行される。
# 上のマイグレーションファイルにはchangeという名前のメソッドが作成されており、マイグレーションの実行時に呼び出される。このメソッドで定義されてる操作は取り消しが可能。つまり、Railsはchangeメソッドで行われたマイグレーションを必要に応じて元に戻すことができる。このマイグレーションを実行すると、articlesというテーブルが作成され、文字列カラムとテキストカラムが1つずつ作成される。Railsは、マイグレーション時に作成日と更新日を追跡するためのタイムスタンプフィールドを2つ作成する。これは指定がなくても自動的に行われる。