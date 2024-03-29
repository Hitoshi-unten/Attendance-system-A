Rails.application.routes.draw do

  root 'static_pages#top'
  # 最初に設定したトップページは、このアプリケーションの初期ページとなるのでroot設定に割り当てることにする。このように置き換えるとコントローラ#アクションへの関連付けが変わり、ルートURL/へのGETリクエストが、StaticPagesコントローラのtopアクションにルーティングされるようになる。ルートURL/へアクセスした時にトップページが表示されるようになる。アプリケーションのルーティングファイルの内容。外部からのリクエストをコントローラーとアクションに振り分ける方法を、DSL（ドメイン特化言語：domain-specific language）という特殊な言語でこのファイルを記述する。root 'static_pages#top'と記述することで、アプリケーションのルートURLへのアクセスをstatic_pagesコントローラのtopアクションに割り当てるようRailsに指示が伝わる。root 'static_pages#top'では、/static_pages#topというURLに対するROOTリクエストを、StaticPagesコントローラのtopアクションと結びつけている。
  get '/signup', to: 'users#new'
  # ヘルパー signup_path signup_url HTTPリクエスト GET URL /signup コントローラ#アクション users#new # 同様に、get '/signup', to: 'users#new'はhttps://ad8f32ee195e44f1add884d80b8f5a70.vfs.cloud9.ap-northeast-1.amazonaws.com/というリクエストをusersコントローラのnewアクションに割り当てる。 # ブラウザでhttps://ad8f32ee195e44f1add884d80b8f5a70.vfs.cloud9.ap-northeast-1.amazonaws.com/を表示し、app/views/users/new.html.erbの中に書いた"ユーザー登録"という文字がブラウザ上に表示される。usersControllerのnewアクションへのルーディングが新たに形成され、ビューが正しく表示されたことが確認できる。 # ブラウザから「〜/get/signup」というURLが送信された時に、usersコントローラのtopアクションの処理が実行されるようになる。ブラウザで〜/get/signupを送信してトップページが表示される # ユーザー登録ページのルーティングに設定してある/signupは、Usersコントローラのnewアクションと紐付いている。 # ログイン機能 # 途中のカンマ（,）や、コントローラとアクションの間にある井桁（#）の入れ忘れに注意する。 # このroutes.rbの状態で、実はルーティングヘルパーと呼ばれるパスも生成されている。このパスを使うことで、ビューが改修しやすくなり、コードが読みやすくなるなどのメリットがある。 # ルーティングは、一致するURLをプログラムの記述通りに上から探していく。 # 入力された新規投稿を受け取るためのアクション。１．入力フォームに投稿内容となるテキストを入力する。２．フォームの「投稿ボタン」を押す。３．保存用のアクション（createアクション）が呼び出され、受け取った内容をDBに保存する。# createアクションのURLは.../posts/createとする。フォームの値を受け取るアクションのルーティングでは、postと記述する必要がある。 # ルーティング は、リクエストをどのコントローラに割り振るかを決定するためのもの。1つのコントローラに対して複数のルーティングがあるのはよくあること。 # 「get'URL',to:'コントローラー名#アクション名'」という文法で記述する。このルーティングの設定によって、ブラウザから「〜/login」というURLが送信された時にsessionコントローラーのnewアクションの処理が実行されるようになる。
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

 # アプリケーションに新しくリソースを作成する。ここで言う「リソース」とは、記事、人、動物などのよく似たオブジェクト同士が集まったものを指す。 リソースに対して作成 (create)、読み出し (read)、更新 (update)、削除 (destroy) の4つの操作を行なうことができるようになっており、これらの操作の頭文字を取ってCRUDと呼ぶ。 # Railsのルーティングにはresourcesメソッドがあり、これを用いてRESTリソースへの標準的なルーティングを宣言できる。 # コマンドラインでrails routesコマンドを実行すると、標準的なRESTfulアクションへのルーティングがすべて定義されていることが確認できる。ここで注目なのは、Railsは「users」というリソース名から単数形の「user」を推測し、両者をその意味にそって使い分けているという点。prefix列で単一の項目には単数形のuser、複数項目を扱う場合には複数形のusersが使われているという具合。 # コントローラの内側で定義されたメソッドは、コントローラのアクションになる。このアプリケーションではアクションがuserに対するCRUD操作を担当する。
  resources :bases
 
  resources :users do
    member do
      get 'attendances/edit_one_month' # 勤怠編集ページ
      patch 'attendances/update_one_month'  # まとめて更新 # 注目すべきは、コントローラがattendancesと設定されている点。Userリ����ースに含まれるよう設定したが、attendances/...と記述することによってattendances_edit_one_month_user_pathとルーティングの設定を追加することが可能。URLはusers/1/attendances/edit_one_monthと直感的になる。
      get 'applicant_confirmation'
    end
    
    collection {post :import}
    collection do
      get 'list_of_employees' # 出勤社員一覧
      get 'basic_info_modification' # 基本情報の修正
    end
    resources :attendances, only: :update do # AttendanceリソースとしてはupdateアクションのみでOKでonlyオプションを指定することで、updateアクション以外のルーティングを制限できる。
      member do
        get 'edit_overwork_request'
        patch 'update_overwork_request'
      end
      collection do
        get 'edit_superior_announcement'
        patch 'update_superior_announcement'
        
        patch 'monthly_approval' # 1ヶ月承認申請
        get 'edit_monthly_approval' # 1ヶ月承認申請（上長モーダル表示）
        patch 'update_monthly_approval' # 1ヶ月承認申請（上長モーダル承認）

        get 'edit_working_hours_approval' # 勤怠変更申請（上長モーダル表示）
        patch 'update_working_hours_approval' # 勤怠変更申請（上長モーダル変更送信）

        get 'attendance_log' # 勤怠ログ
      end
    end
  end
end

 #HTTP	URL	アクション	ルーティングヘルパー	目的
 #GET	/users	index	users_path	ユーザーを一覧表示するページ
 #GET	/users/1	show	user_path(1)	特定のユーザーを表示するページ
 #GET	/users/new	new	new_user_path	ユーザーを新規作成するページ
 #GET	/users/1/edit	edit	edit_user_path(1)	ユーザーを編集するページ
 #POST	/users	create	users_path	ユーザーを作成・保存するアクション
 #PATCH	users/1	update	user_path(1)	ユーザーを更新するアクション
 #DELETE	users/1	destroy	user_path(1)	ユーザーを削除するアクション