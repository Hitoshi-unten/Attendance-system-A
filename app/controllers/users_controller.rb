class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :correct_user, only: [:edit, :update]
  before_action :admin_user, only: [:index, :destroy, :edit_basic_info, :update_basic_info]
  before_action :admin_or_correct_user, only: [:show, :update, :edit_one_month, :update_one_month]
  before_action :set_one_month, only: :show
  #before_action :limitation_login_user, only: [:new, :create, :login_page, :login]
  #before_action :メソッド名〜と記述することで、全てのアクションが実行される直前に、ここで指定したアクションが実行されることとなる。
  #set_userを指定しているのでbefore_actionメソッドは同じコントローラ内にあるset_userを実行するという流れ。
  #その結果、全アクションでまずは #@current_userを定義しようとし、@current_userが存在すればログイン状態、nilならログアウト状態ということがわかるようになります。
  #onlyオプションで実行したいアクションのみ記述することができる。

  def index #(一覧画面)
    @users = if params[:search]
      # ビューで使う変数はアクション内に定義する。変数に「＠」が付いている事にも意味がある。def [アクション名] ... endの間に変数を定義することができる
      # Railsでは、変数名を「@」から始めることでその変数を「インスタンス変数」として定義することが出来る。そしてこのインスタンス変数をビューで使用することができる。「＠」をつけない場合、その変数はローカル変数となり、ビューで変数を使おうとしてもスコープ（変数が使える範囲）から外れてしまい使用することが出来ない。
      # searchされた場合は、原文+.where('name LIKE ?', "%#{params[:search]}%")を実行
      User.paginate(page: params[:page]).where('name LIKE ?', "%#{params[:search]}%")
    else
      # searchされていない場合は、原文そのまま
      User.paginate(page: params[:page])
    end
  end

  def show # (特定の投稿を表示する画面)
    @worked_sum = @attendances.where.not(started_at: nil).count
  end

  def new # (投稿の新規作成画面)
    @user = User.new
  end

  def create #(投稿の新規保存)
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit # (投稿の編集画面)
  end

  def update # (投稿の更新保存)
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @user
    else
      render :edit # renderメソッド かなり簡潔な内容だが、これでeditアクションを経由せずedit.html.erbを直接表示することが可能。renderメソッドを使うと、redirect_toメソッドを使った時と違い、そのアクション（今回はupdateアクション）内で定義したインスタンス変数をそのまま使用することができる。            
    end
  end

# 「リダイレクトするときは..._urlと指定する」とだけ覚えておく
  def destroy # (投稿の削除)
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def edit_basic_info
  end
  
  def update_basic_info
    if @user.update_attributes(basic_info_params)
      flash[:success] = "#{@user.name}の基本情報を更新しました。"
    else
      flash[:danger] = "#{@user.name}の更新は失敗しました。<br>" + @user.errors.full_messages.join("<br>")
    end
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :department, :password, :password_confirmation)
    end
    
    def basic_info_params
      params.require(:user).permit(:department, :basic_time, :work_time)
    end

 # beforeフィルター
    
 # ログイン済みのユーザーか確認します。    
    def logged_in_user
      unless logged_in?
        flash[:danger] = "ログインしてください。"
        redirect_to login_url
      end
    end

 # アクセスしたユーザーが現在ログインしているユーザーか確認します。    
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end
    
    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end