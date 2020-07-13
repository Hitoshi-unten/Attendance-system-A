Rails.application.routes.draw do
  root 'static_pages#top' 
  # 左記のroot 'static_pages#top'では、/static_pages#topというURLに対するROOTリクエストを、StaticPagesコントローラのtopアクションと結びつけています。
  get '/signup', to: 'users#new'
  # ブラウザから「〜/get/signup」というURLが送信された時に、usersコントローラのtopアクションの処理が実行されるようになる。ブラウザで〜/get/signupを送信してトップページが表示される

  # ログイン機能
  get    '/login', to: 'sessions#new'
  post   '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
  
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