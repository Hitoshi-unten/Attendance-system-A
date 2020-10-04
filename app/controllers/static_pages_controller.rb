# トップページを作るにあたって、まずはMVCにおけるC（コントローラ）を生成する。
# generateスクリプトを使用する。次のコマンドをターミナルで実行する。$ rails generate controller StaticPages top
# コントローラ生成コマンドで、topアクションが生成されており、routes.rbファイルには自動的にこのtopアクションで使用されるルーティングが追加されている。
class StaticPagesController < ApplicationController
 # topアクションは、views_static_pagesフォルダからtop.html.erbを探してブラウザに返す
  def top
  end
 # topアクションは現状定義されているだけで中身は空でRubyとしては、 この空のtopメソッドは何も実行することはない。
 # しかし、Railsでは動作が異なる。では実際に何が起こるかというと、/static_page/topというURLにアクセスすると、
 # RailsはStaticPagesコントローラを参照し、topアクションに記述されているコードを実行する。その後、アクションに
 # 対応するビュー(View)を出力する。（今回の場合はapp/views/static_pages/top.html.erb）
end