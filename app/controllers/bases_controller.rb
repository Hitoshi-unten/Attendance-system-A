class BasesController < ApplicationController
  before_action :set_base, only: [:show, :edit, :update, :destroy]
  before_action :admin_user
  
  def index
    @bases = Base.all.order('base_id ASC')
  end
  
  def show
  end

  def new
    @base = Base.new
  end

  def create
    @base = Base.new(base_params)
    if @base.save
      flash[:success] = '拠点情報が追加されました。'
      redirect_to bases_url
    else
      flash[:danger] = '拠点情報は追加されませんでした。'
      redirect_to bases_url
    end
  end

 def edit
   @base = Base.find(params[:id])
 end

 def update
   if @base.update_attributes(base_params)
     flash[:success] = "拠点情報を更新しました。"
     redirect_to bases_url
   else
     flash[:danger] = "拠点情報は更新されませんでした。"
     redirect_to bases_url
   end
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
     params.require(:base).permit(:base_id, :name, :attendance)
   end
end