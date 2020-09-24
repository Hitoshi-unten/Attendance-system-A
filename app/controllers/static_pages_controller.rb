# トップページを作るにあたって、まずはMVCにおけるC（コントローラ）を生成する。
# generateスクリプトを使用する。次のコマンドをターミナルで実行する。$ rails generate controller StaticPages top
class StaticPagesController < ApplicationController
  # topアクションは、views_static_pagesフォルダからtop.html.erbを探してブラウザに返す
  def top
  end
end