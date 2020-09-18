module AttendancesHelper
  
  def attendance_state(attendance)
    # 受け取ったAttendanceオブジェクトが当日と一致するか評価します。
    if Date.current == attendance.worked_on
      # 繰り返し処理中の日付と、実際の日付における当日が一致することを条件としている。
      # 「勤怠データが当日、かつ出勤時間が存在しない場合」に'出勤'。
      return '出勤' if attendance.started_at.nil?
      # 「勤怠データが当日、かつ出勤時間が登録済、かつ退勤時間が存在しない場合」に'退勤'。
      return '退勤' if attendance.started_at.present? && attendance.finished_at.nil?
    end
    # どれにも当てはまらなかった場合はfalseを返します。
    # 「勤怠データが当日でない、または当日だが出勤時間も退勤時間も登録済の場合」にfalse。
    return false
  end
  
  # 出勤時間と退勤時間を受け取り、在社時間を計算して返します。
  def working_times(start, finish) #working_timeメソッドに２つの引数を設定し、受け取った引数を使って時間の計算処理をして値を返す仕組みとなっている。
    format("%.2f", (((finish - start) / 60) / 60.0)) #時間のオブジェクトを計算すると、秒数として結果が出るためこのような計算が成り立つ。
  end
  
  def format_hour(time)
    format('%.f',((time.hour)))
  end
  
  def format_min(time)
    format("%.f",(((time.min))))
    #format("%.d",(((time.min) / 15) * 15))
  end
end
