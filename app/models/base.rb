class Base < ApplicationRecord
  validates :base_id, uniqueness: true, numericality: { :greater_than_or_equal_to => 0 } #数値で0以上
  validates :name, presence: true
  validates :attendance, inclusion: { in:["出勤","退勤"]}
end
