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
  # このset_one_monthメソッドはbefore_actionとして実行する。before_actionは指定のアクションが呼び出される前に実行される。その為、@first_dayと@last_dayはshowアクションからこちらへ引っ越すことになる。
  def set_one_month
    # 下記のコードは長いので改行しているが、実施には次のような三項演算子のプログラムとなっている。@first_day = params[:date].nil? ? Date.current.beginning_of_month : params[:date].to_date @last_day = @first_day.end_of_month
    # if文や上記の三項演算子はコンソールで確認するとわかるが、結果を戻り値として返すので@first_day変数にそのまま代入することが可能となる。・・・意味がわからない！
    @first_day = params[:date].nil? ?
    Date.current.beginning_of_month : params[:date].to_date #@first_dayではまず当日を取得するためDate.currentを使っている。これにRailsのメソッドであるbeginning_of_monthを繋げることで当月の初日を取得することができる。
    @last_day = @first_day.end_of_month #@last_dayでは、@first_dayをはじめに記述することでDate.currentを２回実行せずに済む。こういった工夫は大事。end_of_monthは当月の終日を取得することができる。
    # 次にこれらのインスタンス変数を使って、１ヶ月分のオブジェクトが代入された配列を定義する。この配列はメソッド内で後ほど使用するが、showアクションでは使用しない為ローカル変数に代入している。
    one_month = [*@first_day..@last_day] # 対象の月の日数を代入する。
    # ユーザーに紐付く一ヶ月分のレコードを検索し取得する。
    # この構文により、「１ヶ月分のユーザーに紐づく勤怠データを検索し取得する」ことが出来る。
    # @userはメソッド内で定義していないように見えるが、showアクションではbefore_actionとしてset_userメソッドも設定されている。このset_userは今回定義したset_one_monthよりも上に記述することで、beforeアクションの中でも優先的に実行されることになる。その為、このように使用することができる。ここは理解できていない！
    # @userの先を見ると、.attendancesという複数形の記述がある。これはActiveRecord特有の記法で、対象モデル（今回はUserモデル）に紐づくモデルを指定する。UserモデルとAttendanceモデルは１対多の関係なので、attendancesとなる仕組み。
    # さらにこの@user.attendancesに対し、whereメソッドを呼び出している。引数にはworked_onをキーとして定義済みのインスタンス変数を範囲として指定している。
    # この構文により、「１ヶ月分のユーザーに紐づく勤怠データを検索し取得する」ことができる。このオブジェクトに成功した場合、showアクションでも使用することになる為インスタンス変数に代入している。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)

    # unless文は、条件式がfalseと評価された場合のみ、内部の処理を実行する。
    # 条件式を見ると、どちらのオブジェクトにもcountが呼び出されている。countメソッドは、対象のオブジェクトが配列の場合要素数を返す。
    # これにより、１ヶ月分の日付の件数と勤怠データの件数が一致するか評価する。
    # ==演算子により上記の一致した場合はtrue、一致しない場合はfalseが返されるため内部処理が制御される仕組み。
    unless one_month.count == @attendances.count # １ヶ月分の日付の件数と勤怠データの件数（日数）が一致するか評価する。
      # Transaction（トランザクション）とは、指定したブロックにあるデータベースへの操作が全部成功することを保証する為の機能でデータの整合性を保つために使用されている。
      # 勤怠データを生成する繰り返し処理のコードを、トランザクションのブロックで囲んでいて、このブロック内で例外処理（!）が発生した場合にロールバックが発動する仕組みとなっている。
      # 何らかの原因で、勤怠データが期待通りに生成できずcreate!メソッドが例外を吐き出した時に、この繰り返し処理が始まる前の状態のデータベースに戻るようになっている。ロールバック後は実行がスキップされ、fフラッシュメッセージを代入してトップページにリダイレクトされる。
      # トランザクションの内容は理解しようとすると時間がかかってしまうため、次のように覚えておく。
      # 「まとめてデータを保存や更新するときに、全部成功したことを保証するための機能」
      # 「万が一途中で失敗した時は、エラー発生時専用のプログラム部分までスキップする」
      ActiveRecord::Base.transaction do # トランザクションを開始します。
        # 繰り返し処理により、1ヶ月分の勤怠データを生成します。
        # １ヶ月分の日付の件数と勤怠データの件数が一致しなかった場合の処理。
        # 内部ではone_monthに対してeachメソッドを呼び出している。
        # ブロックに対してはdayブロック変数を定義している。
        # このdayブロック変数が、ブロック内の@user.attendances.create!(worked_on: day)で呼び出せる仕組みになっている。
　　　　# ここでは１ヶ月分の日付が繰り返し処理されて実行されており、createメソッドによってworked_onに日付の値が入ったAttendanceモデルのデータが生成されている。
        one_month.each do |day|
          @user.attendances.create!(worked_on: day)
        end
      end
      # @attendancesの定義箇所を２箇所にふやしている。これは実際に日付データを繰り返し処理で生成した後にも、正しく@attendances変数に価が代入されるようにするため。
      # それぞれの文末には、orderメソッドを付け加えた。このメソッドは取得したデータを並び替える働きをする。
      # 下記のように記述することで、取得したAttendanceモデルの配列をworked_onの値をもとに昇順に並び替えることができる。
      @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "ページ情報の取得に失敗し���した、再アクセスしてください。"
    redirect_to root_url
  end
end