class MonthApproval < ApplicationRecord
  # belongs_to :user
    # 更新を許可するカラムを定義
  def self.updatable_attributes
    ["id", "applicant_user_id", "approval_superior_id", "approval_status", "approval_month"]
  end
end
