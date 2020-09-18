class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_one_month, :update_one_month]
  before_action :logged_in_user, only: [:update, :edit_one_month]
  before_action :admin_or_correct_user, only: [:update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :edit_one_month

  
  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"
  
  def update
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.change(sec: 0))
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
  
  private
  
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
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