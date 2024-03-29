module AttendancesHelper
  # 条件式にしてもlink_toにしてもほぼ同じ構文が並んでいる。特にlink_toのコードはボタンのテキスト以外が全く同じという状態。# 今のうちにこれはリファクタリングしておく。今回はAttendancesヘルパーモジュールに１つメソッドを作る。# attendance_stateというヘルパーメソッドを定義した。引数は1つ指定している。渡される引数は、繰り返し処理されているAttendanceモデルオブジェクトを想定している。# 目的としては、「このメソッドを使って勤怠登録ボタンのテキストには何が必要か？または必要ないか？」をこのメソッドで判定すること。# このメソッドでは戻り値が３パターンある。# 1つめは「勤怠データが当日、かつ出勤時間が存在しない場合」に'出勤'。# 2つめは「勤怠データが当日、かつ出勤時間が登録済、かつ退勤時間が存在しない場合」に'退勤'。# 3つめは「勤怠データが当日ではない、または当日だが出勤時間も退勤時間も登録済の場合」にfalse。# このメソッドの戻り値と、if文のルールを使ってビューを制御しようということ。# if文は条件式の結果がtrueなら処理を実行しfalseなら何もしない。上記の戻り値のうち、'出勤'と'退勤'はtrueとして判断される。# つまり、このような構文が成り立つ。# <% if btn_text = attendance_state(day) %>#   <%= link_to "#{btn_text}", user_attendance_path(@user, day), method: :patch, class: "btn btn-primary btn-attendance" %># <% end %># この構文では、まずif文の条件式に記述されているattendance_stateが呼び出される。引数には繰り返し処理中のAttendanceオブジェクトを渡している。# このメソッドからは3パターンの戻り値が返ってくる。その戻り値をbtn_text変数に代入している。# こうすることで、処理が実行された時、戻り値の値を使用できる仕組み。falseが返ってきた場合はそもそも処理が実行されない（ボタンを表示しないということ）。# このコードはビューに組み込む。
  def attendance_state(attendance)  # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on# 繰り返し処理中の日付と、実際の日付における当日が一致することを条件としている。
      # 「勤怠データが当日、かつ出勤時間が存在しない場合」に'出勤'。
      return '出社' if attendance.started_at.nil?
      # 「勤怠データが当日、かつ出勤時間が登録済、かつ退勤時間が存在しない場合」に'退勤'。
      return '退社' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。# 「勤怠データが当日でない、または当日だが出勤時間も退勤時間も登録済の場合」にfalse。
    return false
  end
  # 勤怠表にある在社時間の項目機能を追加する。# 在社時間は、出勤してから退勤登録するまでの時間を指す。# そしてこの時間を、ページ上部で表示しているような基本情報と同様の書式にて表示する。# 在社時間を求める計算処理を実装していくのにビューに直接計算処理を記述するのではなく出来るだけヘルパーやインスタンス変数を利用してシンプルな記述のビューを心がける。# 今回はAttendancesヘルパーモジュールに、在社時間を計算するworking_timesメソッドを定義する事にする。# 出勤時間と退勤時間を受け取り、在社時間を計算して返します。

  def working_times(start, finish) # working_timeメソッドに２つの引数を設定し、受け取った引数を使って時間の計算処理をして値を返す仕組みとなっている。
    format("%.2f", (((finish - start) / 60) / 60.0)) #時間のオブジェクトを計算すると、秒数として結果が出るためこのような計算が成り立つ。計算結果はformatメソッドにより、指定の書式に変換することで最終的な表示結果になる。
  end

  def edit_working_times(start, finish, edit_next_day) # working_timeメソッドに２つの引数を設定し、受け取った引数を使って時間の計算処理をして値を返す仕組みとなっている。
    if edit_next_day == true
      format("%.2f", ((finish.hour - start.hour) + (finish.min - start.min) / 60.0) + 24)
    else  
      format("%.2f", ((finish.hour - start.hour) + (finish.min - start.min) / 60.0)) #時間のオブジェクトを計算すると、秒数として結果が出るためこのような計算が成り立つ。計算結果はformatメソッドにより、指定の書式に変換することで最終的な表示結果になる。
    end
  end
  
  def format_hour(time)
    format('%.f',((time.hour)))
  end
  
  def format_min(time)
    format("%.f",(((time.min))))
    #format("%.d",(((time.min) / 15) * 15))
  end
  
   def over_times(scheduled_end_time, designated_work_end_time, next_day)
     if next_day == true # if is_next_dayの書き方の方がエンジニアらしい書き方、next_dayがTrue.ClassかFalse.Classか判定するから==trueと書かなくていい。
       format("%.2f", ((scheduled_end_time.hour - designated_work_end_time.hour) + ((scheduled_end_time.min - designated_work_end_time.min) / 60.0)) + 24)
     else
       format("%.2f", ((scheduled_end_time.hour - designated_work_end_time.hour) + ((scheduled_end_time.min - designated_work_end_time.min) / 60.0)))
     end
   end
end
