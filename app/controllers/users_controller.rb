class UsersController < ApplicationController
  require 'csv'
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :applicant_confirmation]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :applicant_confirmation]
  # このように記述することで、editとupdateアクションが実行される直前にlogged_in_userメソッドが実行されるようになる。
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
  # 【admin_user】＝「管理者は遷移可」
  before_action :admin_or_correct_user, only: [:show, :update, :edit_one_month, :update_one_month]
  # 【admin_or_correct_user】＝「管理者は遷移可」または「遷移したいページが現在ログインしているユーザー自身のページだった場合遷移可」というメソッド。
  before_action :set_one_month, only: [:show, :applicant_confirmation]
  # before_action :メソッド名〜と記述することで、全てのアクションが実行される直前に、ここで指定したアクションが実行されることとなる。
  # set_userを指定しているのでbefore_actionメソッドは同じコントローラ内にあるset_userを実行するという流れ。
  # その結果、全アクションでまずは #@current_userを定義しようとし、@current_userが存在すればログイン状態、nilならログアウト状態ということがわかるようになります。
  # onlyオプションで実行したいアクションのみ記述することができる。

  def index 
    @users = User.all
    # @attendances = Attendance.all
  end
  
  def import
    #fileはtmpに自動で一時保存される
    User.import(params[:file])
    flash[:success] = "ユーザー情報をインポートしました。"
    redirect_to users_path 
  end
    
  def show # (特定の投稿を表示する画面)
    if current_user.admin?
      redirect_to users_url
    end
    # countメソッドは配列の要素数を取得することができる。今回はwhere.notを用いて、記述している。
    @worked_sum = @attendances.where.not(started_at: nil).count #「１ヶ月分の勤怠データの中で、出勤時間が何もない状態ではないものの数を代入」
    @attendance = @user.attendances.find_by(worked_on: @first_day)
    @superior_users = User.where(superior: true).where.not(id: @user.id)
    # 上長 申請中をカウントして赤字で表示する
    # 上長 自身宛ての申請があり、かつステータスが申請中の時、その数をカウントする
    if @user.superior?
      @edit_superior_announcement_count = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.id).count #残業申請のお知らせの件数
      @monthly_approval_count = Attendance.where(approval_status: "申請中", approval_superior_id: @user.id).count #所属長承認申請のお知らせの件数
      @edit_working_hours_approval_count = Attendance.where(edit_status: "申請中", edit_superior: @user.id).count #勤怠変更申請のお知らせの件数
    end

    # 月初日を取得。
    # 申請者が1ヶ月申請を押したときに月初日に「申請中」が入る
    # 上長が「承認」「否認」「なし」のどれかを選択することでstatusが変更される
    @first_day_monthly_request = @user.attendances.find_by(worked_on: @first_day)
    if @first_day_monthly_request.approval_superior_id.present?
      @name = User.find(@first_day_monthly_request.approval_superior_id).name
      if @first_day_monthly_request.approval_status == "申請中"
        @status_updated = "所属長 #{@name}に申請中"
      elsif @first_day_monthly_request.approval_status == "承認"
        @status_updated = "所属長承認 #{@name}から承認済"
      elsif @first_day_monthly_request.approval_status == "否認"
        @status_updated = "所属長否認 #{@name}から否認済"
      end
    end
    respond_to do |format|
      format.html
      format.csv do |csv|
        send_attendances_csv # CSV出力用のカスタムメソッドを呼び出す
        # send_data render_to_string, filename: "index.csv", type: :csv #csv用の処理
      end
    end
  end

  def new # (投稿の新規作成画面)
    @user = User.new
  end

  def create #(投稿の新規保存)
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  # フォームを送信すると、フォームに含まれるフィールドはパラメータ（params）としてRailsに送信される。これらのパラメーターは、受けとったコントローラ内のアクションで参照可能となっており、これを用いて特定のタスクを実行する。
  # ここでrenderメソッドは非常に単純なハッシュを引数にとる。ハッシュのキーはnew、ハッシュの値は・・・。
  # paramsメソッドは、フォームから送信されてきたパラメー���（つまりフォームのフィールド）を表すオブジェクト。paramsメソッドは、ActionController：：Parametersオブジェクトを返す。文字列またはシンボルを使って、このオブジェクトのハッシュのキーを指定���きる。
  # paramsメソッドは今後多用することになるのでしっかり理解しておく。http://www.example.com/?username=dhh&email=dhh@email.com���いうURLで説明すると、params[:username]の値が「dhh」、params[:email]の値が「dhh@email.com」となる。
  # Railsのすべてのモデルは初期化時に属性(フィールド)を与えられ、それらはデータベースカラムに自動的に対応付けられる。メソッドの1行目ではまさにそれが行われている (取り出したい属性はparamsの中にある)。次の@user.saveで、このモデルをデータベースに保存する。最後に、ユーザーをshowアクションにリダイレクトする (showアクションはこの後定義する)。訳注: モデルを保持している@userを指定するだけで、そのモデルを表示するためのshowアクションにリダイレクトされる点に注目。
  # TIPS: userが小文字で統一されているのに、User.newのUだけなぜ大文字なのか気になる方へ: これはapp/models/user.rbで定義されているUserクラスを表します。Rubyのクラス名は大文字で始めなければなりません。
  # createアクションも、saveの結果がfalseの場合には、redirect_toではなく、newテンプレートに対するrenderを実行する。ここでrenderメソッドを使う理由は、ビューのnewテンプレートが描画されたときに、@userオブジェクトがビューのnewテンプレートに返されるようにするため。renderによる描画は、フォームの送信時と同じリクエスト内で行われる。対照的に、redirect_toはサーバーに別途リクエストを発行するようブラウザに対して指示するので、やりとりが1往復増える。
  # @ user = User.new(params[:user])は@user = User.new( name: "", email: "", password: "[FILTERED", password_confirmation: "[FILTERED]")と同じ取り扱いであるということになる。

  def edit # (投稿の編集画面)
  end

  def update # (投稿の更新保存)
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit # renderメソッド かなり簡潔な内容だが、これでeditアクションを経由せずedit.html.erbを直接表示することが可能。renderメソッドを使うと、redirect_toメソッドを使った時と違い、そのアクション（今回はupdateアクション）内で定義したインスタンス変数をそのまま使用することができる。            
    end
  end

# 「リダイレクトするときは..._urlと指定する」とだけ覚えておく
  def destroy # (投稿の削除)
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end
  
  def edit_basic_info
  end
  
  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end
  
  def list_of_employees
    @in_working_users = User.in_working_users
  end

  def basic_info_modification
  end
  
  def edit_overwork_request
    @user = User.find(params[:user_id]) #上記レコードのuser_idをもとにユーザー情報を探してくる
    @attendance = Attendance.find(params[:id]) #idの値が一致するレコードを探してくる
    @superiors = User.where(superior: true).where.not(id: @user.id) #上長は２名いるので@superiorsと複数形にする。superiorがtrueなのは上長だけなのでそのまま条件式にする。複数取り出すためにwhereメソッドを使用。idが自分のidではない=where.not(id:@user.id)   # where 出勤中の社員を取り出す。whereは複数件の条件のあったものを取り出す。find、find_byと合わせて覚えておく。@インスタンス変数を使う。 
  end

  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    if @attendance.update_attributes(overwork_params)
      flash[:success] = "残業を申請しました。"
    else
      flash[:danger] = "申請をキャンセルしました。"
    end
    redirect_to user_url(@user)
  end

  # 上長が申請者の勤怠を確認（勤怠を確認する 確認ボタン）
  def applicant_confirmation
  end

  # 勤怠修正ログ
  def attendance_log
    @user = User.find(params[:id])
    if params["worked_on(1i)"].present? && params["worked_on(2i)"].present? # worked_on(1i)は年　worked_on(2i)は月
      selected_year_and_month = "#{params["worked_on(1i)"]}/#{params["worked_on(2i)"]}" # "2021/08"
      @day = DateTime.parse(selected_year_and_month) if selected_year_and_month.present? # @day = Sat, 01 August 2021 00:00:00 +0000
      @attendances = @user.attendances.where(edit_status: "承認").where(worked_on: @day.all_month) # 承認済みをwhereで絞り込む
    else
      @attendances = @user.attendances.where(edit_status: "承認").order("worked_on ASC") #全ての承認済みを日付順で出す
    end
  end

  def send_attendances_csv
    csv_data = CSV.generate do |csv|
      header = %w(日付 出社時間 退社時間 備考)
      csv << header
      @attendances.each do |attendance|
        values = [
          l(attendance.worked_on, format: :short),
          if attendance.started_at.present?
            l(attendance.started_at, format: :time)
          else
            ''  
          end,
          if attendance.finished_at.present?  
            l(attendance.finished_at, format: :time)
          else
            ''
          end,
          attendance.note
          ]
        csv << values
      end
    end
    send_data(csv_data, filename: "勤怠一覧表.csv")
  end

  private

    def user_params #ユーザーの送信情報を制御するuser_params
      params.require(:user).permit(:name, :email, :affiliation, :employee_number, :uid, :password, :basic_work_time, :designated_work_start_time, :designated_work_end_time) # (:name, :email, :department, :password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:affiliation, :basic_time, :work_time)
    end

    def overwork_params
      params.require(:attendance).permit(:finish_overwork, :next_day, :work_content, :instructor_confirmation, :overtime_status)
    end
 
 # Railsにはセキュリティの高いアプリケーションを開発するのに便利な機能が多数ある。これはstrong_parametersと呼ばれるもので、コントローラのアクションで本当に使ってよいパラメータだけを厳密に指定することを強制するもの。
 # なぜそんな面倒なことをしないといけないのか。コントローラが受け取ったパラメータをノーチェックでまるごと自動的にモデルに渡せるようにする方が確かに開発は楽だが、パラメータをこのように安易に渡してしまうと、パラメータがチェックされていない点を攻撃者に悪用される可能性がある。たとえば、サーバーへのリクエストに含まれる新規投稿送信フォームに、もともとフォームになかったフィールドが攻撃者によって密かに追加され、アプリケーションの整合性が損なわれる可能性が考えられる。チェックされていないパラメータをまるごとモデルに保存する行為は、モデルに対する「マスアサインメント」と呼ばれている。これが発生すると、正常なデータの中に悪意のあるデータが含まれてしまう可能性がある。
 # そこで、コントローラで渡されるパラメータはホワイトリストでチェックし、不正なマスアサ��ンメントを防がなければならない。この場合、createでパラメータを安全に扱うために、:name, :email, :department, :password, :password_confirmationパラメータの利用を「許可」し、かつ「必須」であることを指定したいのです。そのための構文によって、requireメソッドとpermitメソッドが導入される。
 # この記法を毎回繰り返すのは煩雑なので、��とえばcreateアクションとupdateアクションで共用できるようにこのメソッドをくくりだしておくのが普通。くくりだしたメソッドは、マスアサインメントを避けるだけでなく、外部から不正に呼び出されることのないようにprivate宣言の後に置いておく。
 # 各コントローラの標準的なCRUDアクションは、多くの場合index、show、new、edit、create、update、destroyの順で配置される。この順番でなくても構わないが、これらがいずれもpublicメソッドである点に注意する。コントローラのpublicメソッドはprivateより前に配置しなければならない。

 # ログイン済みのユーザーか確認します。    
    def logged_in_user
      unless logged_in?
        flash[:danger] = "ログインしてください。"
        redirect_to login_url
      end
    end

 # アクセスしたユーザーが現在ログ��ンしているユーザーか確認します。    
    def correct_user
      @user = User.find(params[:id])
      unless current_user.admin
        redirect_to(root_url) unless current_user?(@user)
      end
    end
 # ここでいくつか注意すべき点がある。ここではUser.findを用いて、取り出したい記事をデータベースから探している。
 # このとき、リクエストの:idパラメータを取り出すためにparams[:id]を引数としてfindに渡している。
 # そして、取り出した記事オブジェクトへの参照を保持するために、通常の変数ではなく、インスタンス変数 (@を冒頭に
 # 付けることで示す) が使われている点にも注目。これは、Railsではコントローラのインスタンス変数はすべてビューに
 # 渡されるようになっているから (訳注: Railsはそのために背後でインスタンス変数をコントローラからビューに絶え間
 # なくコピーし続けている)。
 # findメソッドを使ってユーザーオブジェクトを取得し、インスタンス変数に代入。
 # ユーザーのidの取得ではparamsを使っています。
 # Usersコントローラにリクエストが送信される��、上記のparams[:id]は/users/1の1に置き換わる。
 # ���まり、User.find(params[:id])は、User.find(1)となる。
 # /users/1というURLと、デバッグ情報にあるid: '1'からidが一致していることが確認できる。
 # つまり、/users/2でアクセスすれば、idが2のユーザーを取得し、表示しようとするページとなる。
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end