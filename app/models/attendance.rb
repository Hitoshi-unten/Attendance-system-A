class Attendance < ApplicationRecord
  # belong_to :userはUserモデルと１対１の関係を示している。
  # rails g model Attendance worked_on:date started_at:datetime finished_at:datetime note:string user:references これをターミナルで実行するとAtetndanceモデルが生成される。
  # 生成されたコードでは、Userモデルと１対１の関係を示すbelongs_to :userというコードが記述されている。これは先ほど実行したコマンドにuser:referenceという引数を含めたため。
  # この引数を使うと、自動的にuser_id属性が追加されActiveRecordがUserモデルとAttendanceモデルを紐づける準備をしてくれる。
  belongs_to :user
  # 日付取り扱いは存在性の検証が必要。
  validates :worked_on, presence: true
  # noteは一言メモ、最大文字数を50文字と設定。
  validates :note, length: { maximum: 50 }

  # Railsでは、モデルの状態を確認し、無効な場合errorsオブジェクトにメッセージを追加するメソッドを作成することができる。
  # このメソッドを作成後、バリデーションメソッド名を指すシンボルを渡しvalidateクラスメソッドを使って登録する必要がある。
  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at

  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効
  validate :started_at_than_finished_at_fast_if_invalid
  
  validate :started_at_and_finished_at, on: :update_one_month
  
  validate :finished_at_is_invalid_without_a_finished_at, on: :invalid_finished_at
  
 # blank?は対象がnil "" " " [] {}のいずれかでtrueを返す。
 # present?はその逆（値が存在する場合）にtrueを返す。
 # &&は左右どちらもtrueの時、trueを返す。（true && falseやfalse && trueやfalse && falseの場合はfalseを返す）
 
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end

  
  def started_at_than_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
    end
  end
  
  def finished_at_is_invalid_without_a_finished_at
    if started_at.present? && finished_at.blank?
      errors.add(:finished_at, "が必要です") unless Date.current
    end
  end
end
  # def started_at_and_finished_at
  #   errors.add("出勤時間と退勤時間の入力が必要です") if started_at.present? && finished_at.blank?
  # end
  
  # 「今日の日付が存在し、かつ、出勤時間がpresentであり、かつ、退勤時間がblankである」場合以外は、バリデーションでエラーを出力する
  # 「出勤時間がpresentであり、かつ、退勤時間がblankである」場合は、バリデーションでエラーを出力する。ただし今日の日付が存在する場合は除く。
  #  AttendanceモデルをUserモデルと分けて追加する理由は、Userモデルでは日付ごとに登録が必要な出勤時間や退勤時間の情報を持つことができないから。この問題を解決するために別モデル（Attendanceモデル）を用意して勤怠情報を日付ごとにレコードとして管理、１つのレコードをUserモデルと紐付けることによりユーザーの勤怠情報として取り扱えるようにする。
  # id integer ID worked_on date日付取り扱い started_at datetime 出勤時刻 finished_at datetime 退勤時刻 note string 備考 user_id integer ユーザを紐付ける created_at datetime 作成日時 updated_at datetime 更新日時
  # 自らを管理するためのidと、Userモデルと紐づけるためのuser_idを設定。user_idでユーザーを特定し、ActiveRecord特有の設定でモデル同士を紐付ける。