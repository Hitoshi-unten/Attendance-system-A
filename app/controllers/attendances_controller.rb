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

  # 勤怠編集（編集）
  def edit_one_month
    # URLのidにはattendanceのidが入っている
    @user = User.find(params[:id]) #上記レコードのuser_idをもとにユーザー情報を探してくる
    # @attendance = Attendance.find(params[:id]) #idの値が一致するレコードを探してくる
    @superiors = User.where(superior: true).where.not(id: @user.id) #上長は２名いるので@superiorsと複数形にする。superiorがtrueなのは上長だけなのでそのまま条件式にする。複数取り出すためにwhereメソッドを使用。idが自分のidではない=where.not(id:@user.id)
  end

  # 勤怠編集（更新）
  def update_one_month
    # トランザクション（例外処理）を開始。
    ActiveRecord::Base.transaction do
    # データベースの操作を保証したい処理をここに記述する。
      attendances_params.each do |id, item| #attendanceをeachしてidとitemって分ける、idのところに32とか33とか34が入ってくる、itemのところにedit_started_atとかのいくつかの項目が入ってくる。ただし、itemはここで定義した項目ではなくて、attendance_paramsのストロングパラメーターで定義した項目がある、あそこで定義した項目がitemになる。
        # if item[:edit_superior].blank?
            # if item[:edit_started_at].present? || item[:edit_finished_at].present? || item[:note].present?
            #   flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
            #   redirect_to attendances_edit_one_month_user_url(@user) and return
            # end
          if item[:edit_superior].present?
            if item[:edit_started_at].present? && item[:edit_finished_at].blank?
              flash[:danger] = "退勤時間の入力がない為、更新をキャンセルしました。"
              redirect_to attendances_edit_one_month_user_url(@user) and return
            elsif item[:edit_started_at].blank? && item[:edit_finished_at].present?
              flash[:danger] = "出勤時間の入力がない為、更新をキャンセルしました。"
              redirect_to attendances_edit_one_month_user_url(@user) and return
            elsif (item[:edit_next_day] == "false") && (item[:edit_started_at] > item[:edit_finished_at])
              flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
              redirect_to attendances_edit_one_month_user_url(@user) and return
            elsif item[:note].blank?
              flash[:danger] = "備考の入力がない為、更新をキャンセルしました。"
              redirect_to attendances_edit_one_month_user_url(@user) and return 
            end
            item[:edit_status] = "申請中"
            attendance = Attendance.find(id)
            attendance.update!(item)
          end
        end
      end
    # トランザクションによる例外処理の分岐になる。
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐になる。
    # ここに例外が発生した時の処理を記述する。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_one_month_user_url(@user) and return
  end

  # 残業申請（編集）
  def edit_overwork_request
    # URLのidにはattendanceのidが入っている
    @user = User.find(params[:user_id]) #上記レコードのuser_idをもとにユーザー情報を探してくる
    @attendance = Attendance.find(params[:id]) #idの値が一致するレコードを探してくる
    # @attendance = @user.attendances.find(params[:attendance_id])
    @superiors = User.where(superior: true).where.not(id: @user.id) #上長は２名いるので@superiorsと複数形にする。superiorがtrueなのは上長だけなのでそのまま条件式にする。複数取り出すためにwhereメソッドを使用。idが自分のidではない=where.not(id:@user.id)
  end

  # 残業申請（更新）
  def update_overwork_request
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    params[:attendance][:overtime_status] = "申請中"
    # @attendance = @user.attendances.find(params[:attendance_id])
    if (params[:attendance]["finish_overtime(4i)"].blank?) || (params[:attendance]["finish_overtime(5i)"].blank?) || (params[:attendance][:work_content].blank?) || (params[:attendance][:instructor_confirmation].blank?)
      flash[:danger] = "申請をキャンセルしました。"
    elsif @attendance.update_attributes(overtime_params)
      flash[:success] = "残業を申請しました。"
    end
    redirect_to user_url(@user)
  end
  
  # 残業承認申請（上長モーダル表示）
  def edit_superior_announcement
    # ユーザー定義
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.id).order(:user_id).group_by(&:user_id)
    # @attendances = Attendance.where(overtime_status: "申請中", instructor_confirmation: @user.id).where.not(user_id: @user.id).group_by(&:user_id)
    # @users = User.joins(:attendances).group("users.id").where(attendances:{overtime_status: "申請中"}) #joinsでattendancesのURLを持っているuserを集めてる！
  end

  # 残業承認申請（上長モーダル承認）
  def update_superior_announcement
    n1 = 0
    n2 = 0
    n3 = 0
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
      reply_overtime_params.each do |id, item|
        if item[:change] == "true"
          attendance = Attendance.find(id)
          attendance.update_attributes!(item) #(id, item)
          if item[:overtime_status] == "承認"
            n1 += 1
          elsif item[:overtime_status] == "否認"
            n2 += 1
          elsif item[:overtime_status] == "なし"
            n3 += 1
          end
        end
      end
    end
    flash[:success] = "残業申請→承認を#{n1}件、否認を#{n2}件、なしを#{n3}件送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end
  
  def new_show # 残業申請モーダルの確認ボタン
    @user = User.find(params[:user_id])
    @attendance = Attendance.find(params[:id])
    @first_day = @attendance.worked_on.beginning_of_month #worked_on.日付、beginning_of_month月初日を計算してくれる。
    @last_day = @first_day.end_of_month #end_of_month月末日を計算してくれる。
    @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
    @worked_sum = @attendances.where.not(started_at: nil).count
  end

  # 1ヶ月承認申請
  def monthly_approval
    @user = User.find(params[:user_id])
    @attendance = @user.attendances.find_by(worked_on: params[:attendance][:approval_month])
    params[:attendance][:approval_status] = "申請中"
    if month_approval_params[:approval_superior_id].blank?
      flash[:danger] = "申請先が選択されていないため申請をキャンセルしました。"
    elsif @attendance.update_attributes(month_approval_params)
      flash[:success] = "#{@user.name}の1ヶ月分の勤怠情報を申請しました。"
    end
    redirect_to user_url(@user)
  end
  
  # 1ヶ月承認申請（上長モーダル表示）
  def edit_monthly_approval
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(approval_status: "申請中", approval_superior_id: @user.id).order(:user_id).group_by(&:user_id)
  end
  
  # 1ヶ月承認申請（上長モーダル承認）
  def update_monthly_approval
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
      reply_month_approval_params.each do |id, item|
        if item[:change] == "true"
          attendance = Attendance.find(id)
          attendance.update_attributes!(item) #(id, item) 
        end
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end

  # 勤怠変更申請モーダル（編集）
  def edit_working_hours_approval
    # ユーザー定義
    @user = User.find(params[:user_id])
    @attendances = Attendance.where(edit_status: "申請中", edit_superior: @user.id).order(:user_id).group_by(&:user_id)
  end

  # 勤怠変更申請モーダル（更新）
  def update_working_hours_approval
    n1 = 0
    n2 = 0
    n3 = 0
    ActiveRecord::Base.transaction do
      @user = User.find(params[:user_id])
      reply_working_hours_params.each do |id, item|
        if item[:change] == "true"
          attendance = Attendance.find(id)
          attendance.update_attributes!(item) #(id, item)
          if item[:edit_status] == "承認"
            n1 += 1
          elsif item[:edit_status] == "否認"
            n2 += 1 
          elsif item[:edit_status] == "なし"
            n3 += 1
          end
        end
      end
    end
    flash[:success] = "勤怠変更申請→承認を#{n1}件、否認を#{n2}件、なしを#{n3}件送信しました。"
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to user_url(@user)
  end

  # 勤怠修正ログ
  def attendance_log
    # (params[:id]) の ID を持つUserを定義
    @user = User.find(params[:user_id]) # :current_user_idでも拾える
    # params[:user]["worked_on(1i)"] と params[:user]["worked_on(2i)"] があるときの処理
    if params["worked_on(1i)"].present? && params["worked_on(2i)"].present? # worked_on(1i)は年　worked_on(2i)は月
      selected_year_and_month = "#{params["worked_on(1i)"]}/#{params["worked_on(2i)"]}" # "2021/08"
      @day = DateTime.parse(selected_year_and_month) if selected_year_and_month.present? # @day = Sat, 01 August 2021 00:00:00 +0000
      @attendances = @user.attendances.where(edit_status: "承認").where(worked_on: @day.all_month) # 承認済みをwhereで絞り込む
    elsif params["worked_on(1i)"].blank? || params["worked_on(2i)"].blank?
      @attendances = @user.attendances.where(edit_status: "承認").order("worked_on ASC") #全ての承認済みを日付順で出す
    end
  end
  
  private
  
    # 1ヶ月分の勤怠編集を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:edit_started_at, :edit_finished_at, :note, :edit_status, :edit_superior, :edit_next_day])[:attendances]
    end
    
    # 1ヶ月分勤怠情報を扱う
    def month_approval_params
      params.require(:attendance).permit(:approval_superior_id, :approval_status)
    end
    
    # 1ヶ月分勤怠情報承認を扱う
    def reply_month_approval_params
      params.require(:user).permit(attendances: [:approval_status, :change])[:attendances]
    end
    
    # 残業情報を扱う
    def overtime_params
      params.require(:attendance).permit(:finish_overtime, :next_day, :work_content, :instructor_confirmation, :overtime_status)
    end

    # 残業情報承認を扱う
    def reply_overtime_params
      params.require(:user).permit(attendances: [:change, :overtime_status])[:attendances]
    end
    
    # 勤怠変更情報を扱う
    def working_hours_params
      params.require(:attendance).permit(:work_content, :instructor_confirmation, :edit_status)
    end
    
    # 勤怠変更情報承認を扱う
    def reply_working_hours_params
      params.require(:user).permit(attendances: [:change, :edit_status])[:attendances]
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