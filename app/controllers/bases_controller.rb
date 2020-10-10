class BasesController < ApplicationController
  before_action :set_base, only: :update
  
  def index
    @base = Base.new
    @bases = Base.all.order('base_id ASC')
  end
  
  def show
  end

 def update
   if @base.update_attributes(base_params)
     flash[:success] = "拠点の更新に成功しました。"
   else
     flash[:danger] = "#{@bases.name}の更新は失敗しました。<br>" + @bases.errors.full_messages.join("<br>")
   end
   redirect_to bases_url
 end
  
  def create
    @base = Base.new(base_params)
    if @base.save
      flash[:success] = '拠点情報を作成しました。'
      redirect_to bases_url
    else
      flash[:danger] = '拠点情報の作成に失敗しました。'
      render :index
    end
  end

  def new
    @base = Base.new
  end
  
  def destroy
    @base.destroy
    flash[:success] = "#{@base.name}のデータを削除しました。"
    redirect_to bases_url
  end
  
  private
  
    def set_base
      @base = Base.find(params[:id])
    end

    def base_params
      params.require(:base).permit(:base_id, :name, :attendances)
    end
end