# AttendanceモデルをUserモデルと分けて追加する理由は、「Userモデルでは日付ごとに登録が必要な出勤時間や退勤時間の情報を持つことができない」からである。
# この問題を解決するため、別モデル（Attendanceモデル）を用意して勤怠情報を日付ごとにレコードとして管理、1つのレコードをuserモデルと紐づける事によってユーザーの勤怠情報として取り扱えるようにする。
# つまり、「一人のユーザー」は「複数の勤怠データ」を持っている。１対多の関係が成り立つ。
# 上記を実現できる仕様を考慮すると、Attendanceモデルは次のような構造となる。id ID worked_on 日付取り扱い started_at 出勤時刻 finished_at 退勤時刻 note 備考 user_id ユーザーを紐づける created_at 作成日時 updated_at 更新日時
# 自らを管理するためのidと、Userモデルを紐付けるためのuser_idを設定する。user_idでユーザーを特定し、ActiveRecord特有の設定でモデル同士を紐付ける。
class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month

# 定数は変数と違い、値を変えることはできない。定数は大文字表記を使う。
# 今回は更新エラー用のテキストを2ヶ所で使用しているため、このように定義した。
# 必ずこうしなければならないものではないが、例えばこれが10ヶ所、100ヶ所となったときにそれらの値をまとめて変更しなければならなくなったとする。
# そのような時、定数として定義したものを使用していれば、一回の修正で済ませることができる。仮に文字列をそのまま代入していたとしたら・・・多ければ多いほど時間がかかることになる。
# set_one_monthメソッドはページを出力する前に１ヶ月分のデータの存在を確認し、セットするためのメソッド。このメソッドをbeforeアクションとして実行することで、ページを開きたいのに１ヶ月分のデータがない状態を防ぐように対策した。
# しかし、このset_one_monthメソッドをbefore_actionとして実行するだけだと不具合が発生する。メソッド内で呼び出している@userが定義されていないから。
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0)) # changeメソッドは日時を扱うオブジェクトに対して呼び出すと指定した部分の値を変化させることができる。sec:0と記述することで、秒数を0に変換することができる。他にもyear（年）month（月）day（日）hour（時）min（分）などがある。
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.change(sec: 0))
        flash[:warning] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end
  
  def edit_one_month
  end
  
  def update_one_month
    # トランザクション（例外処理）を開始。
    ActiveRecord::Base.transaction do
    # データベースの操作を保証したい処理をここに記述する。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        # 上記では、attendances_paramsオブジェクトに対してeachメソッドを呼び出している。
        # ブロックにはidとitemを渡している。これはAttendanceモデルオブジェクトのidと、各カラムの値が入った更新するための情報であるitemとなる。
        # 繰り返し処理の中では、まずはじめにidを使って更新対象となるオブジェクトを変数に代入する。その後、update_attributesメソッドの引数にitemを指定し、オブジェクトの情報を更新する。
        # この時、update_attributesの末尾に！が付いていることがとても重要になる。通常、update_attbibutesの更新処理が失敗した場合はfalseが返される。
        # しかし、今回のように！をつけている場合は、falseではなく例外処理を返すことになる。
        # 繰り返し処理で複数のオブジェクトのデータを更新する場合は、これらの処理が全て正常に終了することを保証することが大事になる。
        # あるデータは更新できたが、あるデータは更新できていなかった。となるとデータの整合性がなくなってしまう。
        #attendance.update_attributes!(item) #(context: :invalid_finished_at)
        #attendance.attributes = itemupdate_attributesの末尾に！が付いていることがとても重要になる。
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        end
        #attendance.started_at = item[:started_at]
        #attendance.finished_at = item[:finished_at]
        #attendance.note = item[:note]
        attendance.update!(item)
        
      end
    end
    # トランザクションによる例外処理の分岐になる。
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐になる。
    # ここに例外が発生した時の処理を記述する。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
  end
  
  def edit_overwork_request
    # URLのidにはattendanceのidが入っている
    @attendance = Attendance.find(params[:id]) #idの値が一致するレコードを探してくる
    @user = User.find(@attendance.user_id) #上記レコードのuser_idをもとにユーザー情報を探してくる
  end

  def update_overwork_request
    @attendance = Attendance.find(params[:id])
    if @attendance.update_attributes(overwork_params)
      flash[:success] = "残業を申請しました。"
    else
      flash[:danger] = "申請をキャンセルしました。"
    end
    redirect_to user_url(@user)
  end
  
  private
  
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    # 残業情報を扱う
    def overwork_params
      params.require(:attendance).permit(:finish_overwork, :next_day, :work_content, :instructor_confirmation)
    end
    
    # beforeフィルター
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        # どちらかの条件式がtrueか、どちらもtrueの時には何も実行されない処理になる。
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
        # このフィルターに引っ掛かった場合は、トップページに強制移動になる。
      end
    end
end