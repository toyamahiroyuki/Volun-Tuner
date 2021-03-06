# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, except: %i[top about]

  def top; end

  def about; end

  def show
    @user = User.find(params[:id])

    @notifications = current_user.passive_notifications.page(params[:page]).per(4)

    @user_joins = @user.joined_events.page(params[:user_joins]).per(3)
    @user_hosts = @user.events.page(params[:user_hosts]).per(3)
    @user_likes = @user.liked_events.page(params[:user_likes]).per(3)

  end

  def edit
    @user = User.find(params[:id])
    if @user != current_user
      redirect_to user_path(current_user)
    end
  end

  def update
    user = current_user

    if user.update(user_params)
      redirect_to user_path(user.id)
    else
      @user = current_user
      render 'edit'
    end
  end

  def following
    @title = 'フォロー'
    @user  = User.find(params[:id])
    # @users = @user.following.page(params[:page]).per(5)
    # 上記ではエラーが出るので下記に変更
    @users = @user.following
    @users = Kaminari.paginate_array(@users).page(params[:page]).per(5)
    render 'show_follow'
  end

  def followers
    @title = 'フォロワー'
    @user  = User.find(params[:id])
    @users = @user.followers
    @users = Kaminari.paginate_array(@users).page(params[:page]).per(5)
    render 'show_follow'
  end

  private

  def user_params
    params.require(:user).permit(:username, :lastname, :firstname, :kana_lastname, :kana_firstname, :image, :image_cache, :remove_image)
  end
end
