class MonthApprovalsController < ApplicationController
  before_action :set_user, only: :create
  before_action :set_one_month, only: :create
  
  def index
  end
  
  def new
    @month_approval = MonthApproval.all
  end
  
  def create
    @month_approval = MonthApproval.new(month_approval_params)
    if @month_approval.save
      flash[:success] = "承認申請しました。"
      redirect_to @user
    else
      render :new
    end
  end
  
  def edit
  end

  def show
    @month_approval = MonthApproval.find(params[:user_id])
  end
  
  def update
  end
  
  def destroy
  end
  
  private
    def month_approval_params
      params.permit(:user_id, :approval_superior_id, :approval_status, :approval_month)
    end
end
