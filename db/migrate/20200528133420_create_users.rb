# Model（モデル）はMVCアーキテクチャのうちの１つでRailsとも密接に関わる重要な要素。
# Railsではデータを保存するときにデフォルトでリレーショナルデータベースを使用する。（データを置いておく箱のようなもの）
# リレーショナルデータベースは、データが行で構成されるテーブル構造となっており、各行（１行が１つのデータのイメージ）がデータ型の列（カラム）を持っている。
# 例えば、名前（name）とメールアドレス（email）を持つユーザーをデータベースに保存するのであれば、nameとemailというカラムを持つusersテーブルが必要。
# 各行が１人のユーザーを表すデータとなる。
# テーブルに格納されるデータの例は次のようなイメージ。name ユーザー1、email user1@email.com
# Userデータモデル草案 カラム name データ型 string（文字列型）
# 「name（string型）とemail（string型）の２つの属性を付与したUserモデルを作成する」目的でコマンドを実行する。
# 次のコマンドをターミナルで実行する。$ rails g model User name:string email:string コントローラには複数形（Users）、モデルには単数形（User）で指示する監修は覚えておく。
# このコマンドの結果の１つとしてマイグレーションファイルというファイルが新しく作成されている。
# ファイルの場所はdb/migrate/[timestamp]_create_users.rb（[timestamp]の部分は日時の数値が入る）

class CreateUsers < ActiveRecord::Migration[5.1]
# ファイルにはこれしか書かれていないが、このCreateUsersクラスがActiveRecord::Migration[5.1]クラスを継承していることに注目。これによって基本的なデータベースCRUD (Create、Read、Update、Destroy) 操作やデータのバリデーション（検証: validation）のほか、洗練された検索機能や複数のモデルを互いに関連付ける機能(リレーションシップ) など、きわめて多くの機能をRailsモデルに無償で提供している。
  def change
# このファイル自体はデータベースに与える変更を定義したchangeメソッドの集まりとなっている。
# メソッド内を確認するとまずcreate_tableメソッドを呼び出し:usersと指定することによってusersテーブルを作成する。
# さらにcreate_tableメソッドはブロック変数を持つ（|t|の部分）。
# そしてこのブロックの中でnameとemailカラムをデータベースに作成する。データはstring型。モデル名はUserと単数形だが、テーブル名はusersと複数形となっている。これはRailsの慣習なので覚えておく。
# ブロックの最後にあるt.timestampsは自動的に生成される特別なコードで、created_at（datetime型）、updated_at（datetime型）という２つのマジックカラムを生成する。
# さらにブロック内で記述はないが、id（integer型）という自動採番されるIDの役割を持ったカラムも自動で作成される。
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