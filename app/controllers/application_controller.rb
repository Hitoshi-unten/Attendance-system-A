class ApplicationController < ActionController::Base
  # 全てのコントローラの継承元となるaplicationコントローラにあるメソッドは、usersコントローラでもattendancesコントローラからでも呼び出すことができる。
  protect_from_forgery with: :exception
  include SessionsHelper

  # グローバル変数はプログラムのどこからでも呼び出すことのできる変数で$変数名のように$を用いて表現する。
  # %w{日 月 火 水 木 金 土}はRubyのリテラル表記と呼ばれるもので["日","月","火","水","木","金","土"]の配列と同じように使える。
  $days_of_the_week = %w{日 月 火 水 木 金 土}

  # コントローラは、アプリケーションに対する特定のリクエストを受け取って処理するのが役割。
  # コントローラにはいくつかのアクションがある。いくつかの異なるルーティングに対して、それぞれ異なるアクションを割り当てることができる。それぞれのアクションは、情報を集めてビューに送り出すのが役割。
  
  # paramsハッシュからユーザーを取得する。    
    # findメソッドは引数にidの値となる数値を指定することで、その値を持つデータを取得することができる。
    # @userインスタンス変数に値を代入することで、ビューでもidの値を使用することができる。
    # {id: }というハッシュがparams変数に入っているので、このような記述で「」を取得することができる。

  def set_user
    @user = User.find(params[:id])
  end
  
  # ログイン済みのユーザーか確認します。
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "ログインしてください。"
      redirect_to login_url
    end
  end
  
  # アクセスしたユーザーが現在ログインしているユーザーか確認します。
  def correct_user
    redirect_to(root_url) unless current_user?(@user)
  end

  def limitation_login_user
    if @current_user
      flash[:notice] = "すでにログイン状態です。"
      redirect_to posts_index_url
    end
  end
  
  # システム管理権限所有かどうか判定します。
  def admin_user
    redirect_to root_url unless current_user.admin?
  end  

  # set_one_monthはページを出力する前に1ヶ月分のデータの存在を確認し、セットするためのメソッド。
  # このメソッドをbeforeアクションとして実行することで、ページを開きたいのに１ヶ月分のデータが無い状態を防ぐようにしている。
  def set_one_month 
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date #@firstdayではまず当日を取得するためDate.currentを使っている。これにRailsのメソッドであるbeginning_of_monthを繋げることで当月の初日を取得することができる。
    @last_day = @first_day.end_of_month #@last_dayでは、@first_dayをはじめに記述することでDate.currentを２回実行せずに済む。end_of_monthは当月の終日を取得することができる。
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入します。
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得します。
    # この構文により、「１ヶ月分のユーザーに紐づく勤怠データを検索し取得する」ことが出来る。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)

    unless one_month.count == @attendances.count # １ヶ月分の日付の件数と勤怠データの件数（日数）が一致するか評価する。
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        one_month.each { |day| @user.attendances.create!(worked_on: day) }
      end
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end

  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗し���した、再アクセスしてください。"
    redirect_to root_url
  end
end