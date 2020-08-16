Rails.application.routes.draw do
  root 'static_pages#top' 
  # アプリケーションのルーティングファイルの内容。外部からのリクエストをコントローラーとアクションに振り分ける方法を、DSL（ドメイン特化言語：domain-specific language）という特殊な言語でこのファイルを記述する。
  # root 'static_pages#top'と記述することで、アプリケーションのルートURLへのアクセスをstatic_pagesコントローラのtopアクションに割り当てるようRailsに指示が伝わる。
  # 左記のroot 'static_pages#top'では、/static_pages#topというURLに対するROOTリクエストを、StaticPagesコントローラのtopアクションと結びつけています。
  get '/signup', to: 'users#new'
  # 同様に、get '/signup', to: 'users#new'はhttps://ad8f32ee195e44f1add884d80b8f5a70.vfs.cloud9.ap-northeast-1.amazonaws.com/というリクエストをusersコントローラのnewアクションに割り当てる。
  # ブラウザでhttps://ad8f32ee195e44f1add884d80b8f5a70.vfs.cloud9.ap-northeast-1.amazonaws.com/を表示し、app/views/users/new.html.erbの中に書いた"ユーザー登録"という文字がブラウザ上に表示される。usersControllerのnewアクションへのルーディングが新たに形成され、ビューが正しく表示されたことが確認できる。
  # ブラウザから「〜/get/signup」というURLが送信された時に、usersコントローラのtopアクションの処理が実行されるようになる。ブラウザで〜/get/signupを送信してトップページが表示される
  # ユーザー登録ページのルーティングに設定してある/signupは、Usersコントローラのnewアクションと紐付いている。

  # ログイン機能
  # 途中のカンマ（,）や、コントローラとアクションの間にある井桁（#）の入れ忘れに注意する。
  # ルーティングは、一致するURLをプログラムの記述通りに上から探していく。
  # 入力された新規投稿を受け取るためのアクション。１．入力フォームに投稿内容となるテキストを入力する。２．フォームの「投稿ボタン」を押す。３．保存用のアクション（createアクション）が呼び出され、受け取った内容をDBに保存する。# createアクションのURLは.../posts/createとする。フォームの値を受け取るアクションのルーティングでは、postと記述する必要がある。
  # ルーティング は、リクエストをどのコントローラに割り振るかを決定するためのもの。1つのコントローラに対して複数のルーティングがあるのはよくあること。
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

 # アプリケーションに新しくリソースを作成する。ここで言う「リソース」とは、記事、人、動物などのよく似たオブジェクト同士が集まったものを指す。 リソースに対して作成 (create)、読み出し (read)、更新 (update)、削除 (destroy) の4つの操作を行なうことができるようになっており、これらの操作の頭文字を取ってCRUDと呼ぶ。
 # Railsのルーティングにはresourcesメソッドがあり、これを用いてRESTリソースへの標準的なルーティングを宣言できる。
 # コマンドラインでrails routesコマンドを実行すると、標準的なRESTfulアクションへのルーティングがすべて定義されていることが確認できる。ここでご注目いただきたいのは、Railsは「users」というリソース名から単数形の「user」を推測し、両者をその意味にそって使い分けているという点。prefix列で単一の項目には単数形のuser、複数項目を扱う場合には複数形のusersが使われているという具合。
 # コントローラの内側で定義されたメソッドは、コントローラのアクションになる。このアプリケーションではアクションがuserに対するCRUD操作を担当する。
  resources :users do
    member do
      get 'edit_basic_info'
      patch 'update_basic_info'
      get 'attendances/edit_one_month'
      patch 'attendances/update_one_month'  # この行が追加対象です。
    end
    resources :attendances, only: :update 
  end
end