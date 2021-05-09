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
        if item[:started_at].present? && item[:finished_at].blank?
          flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
          redirect_to attendances_edit_one_month_user_url(date: params[:date]) and return
        end
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
    @user = User.find(params[:user_id]) #上記レコードのuser_idをもとにユーザー情報を探してくる
    @attendance = Attendance.find(params[:id]) #idの値が一致するレコードを探してくる
    @superiors = User.where(superior: true).where.not(id: @user.id) #上長は２名いるので@superiorsと複数形にする。superiorがtrueなのは上長だけなのでそのまま条件式にする。複数取り出すためにwhereメソッドを使用。idが自分のidではない=where.not(id:@user.id)
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
  
  # 残業申請モーダル！
  def edit_superior_announcement
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.name)
    @users = User.joins(:attendances).group("users.id").where(attendances:{overwork_status: "申請中"}) #joinsでattendancesのURLを持っているuserを集めてる！
  end
  
  def update_superior_announcement
    ActiveRecord::Base.transaction do
      @overwork_status = Attendance.where(overtime_status: "申請中").count
      @overwork_status1 = Attendance.where(overtime_status: "承認").count
      @overwork_status2 = Attendance.where(overtime_status: "否認").count
      @overwork_status3 = Attendance.where(overtime_status: "なし").count
      @user = User.find(params[:user_id])
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.update_attributes!(item)
      end
    end
    flash[:success] = "残業申請→申請中を#{@overtime_status}件、承認を#{@overtime_status1}件、否認を#{@overtime_status2}件、なしを#{@overtime_status3}件送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end
  
  def new_show #残業申請モーダルの確認ボタン
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month #worked_on.日付、beginning_of_month月初日を計算してくれる。
    @last_day = @first_day.end_of_month #end_of_month月末日を計算してくれる。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @worked_sum = @attendances.where.not(started_at: nil).count
  end  
  
  private
  
    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at, :finished_at, :note])[:attendances]
    end
    
    # 残業情報を扱う
    def overwork_params
      params.require(:attendance).permit(:finish_overwork, :next_day, :work_content, :instructor_confirmation, :overtime_status)
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