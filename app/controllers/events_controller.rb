# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :authenticate_user!, except: %i[index show search_index pickup]

  def index
    @events = Event.all
  end

  def show
    @event = Event.find(params[:id])
    @join_user = JoinUser.new
    @like = Like.new
    @comments = @event.comments
    @comment = Comment.new
  end

  def new
    @event = Event.new
  end

  def create
    event = current_user.events.build(event_params)
    if event.save
      redirect_to event_path(event.id), notice: '新しいボランティアを主催しました'
    else
      @event = event
      render 'new'
    end
  end

  def edit
    @event = Event.find(params[:id])
    if @event.user_id != current_user.id
      redirect_to event_path(@event)
    end
  end

  def update
    event = Event.find(params[:id])

    if event.user_id != current_user.id
      redirect_to event_path(event)
    elsif event.update(event_params)
      redirect_to event_path(event), notice: 'ボランティア情報を更新しました'
    else
      @event = event
      render 'edit'
    end
  end

  def destroy
    event = Event.find(params[:id])
    if event.user_id != current_user.id
      redirect_to event_path(event)
    elsif event.destroy
      redirect_to user_path(current_user), alert: 'ボランティアを削除しました'
    end
  end

  # イベント確認画面 モーダルの確認画面に変更
  # def confirm
    # パラメータで確認画面へ
    # @event = Event.new(event_params)
    # event_paramsを書けば下記を省略できる
    # @event.title = params[:event][:title]
    # @event.content = params[:content]
    # @event.date = params[:date]
    # @event.time = params[:time]
    # @event.postal_code = params[:postal_code]
    # @event.address = params[:address]
  # end

  def search_index
    # @events = Event.search(params[:search])
    if params[:selected] == 'Title'
      # セレクトボックスがタイトルの時
      search = params[:search]
      @events = Event.page(params[:page]).where(['title LIKE ?', "%#{search}%"]).reverse_order.per(6)
    elsif params[:selected] == 'Content'
      # セレクトボックスが内容の時
      search = params[:search]
      @events = Event.page(params[:page]).where(['content LIKE ?', "%#{search}%"]).reverse_order.per(6)
    elsif params[:tag_name]
      # タグをクリックした時に同じタグ名のイベントを表示
      # 現在の日時を過ぎたイベントは表示しない
      # 日時が近い順に表示
      @events = Event.where('events.start_time > ?', DateTime.now).page(params[:page]).tagged_with(params[:tag_name].to_s).per(6)
    elsif params[:latitude]
      latitude = params[:latitude].to_f
      longitude = params[:longitude].to_f
      # 10kmは約6.21371マイル　半径10km以内のイベントを表示
      # 現在の日時を過ぎたイベントは表示しない
      # 日時が近い順に表示
      @events = Event.where('events.start_time > ?', DateTime.now).page(params[:page]).within_box(6.21371, latitude, longitude).per(6)
    elsif params[:prefecture]
      # 現在の日時を過ぎたイベントは表示しない
      # 日時が近い順に表示
      @events = Event.where('events.start_time > ?', DateTime.now).page(params[:page]).where(prefecture: params[:prefecture]).per(6)
    else
      # 新着順に全件表示
      # 現在の日時を過ぎたイベントは表示しない
      @events = Event.where('events.start_time > ?', DateTime.now).page(params[:page]).reverse_order.per(6)
    end
  end

  def pickup
    # ランダムに取得
    @event_randoms = Event.where('events.start_time > ?', DateTime.now).order('RANDOM()').limit(6)

      if user_signed_in?
        # フォローしているユーザーを取得
        follow_users = current_user.following
        # フォローユーザーのツイートを表示
        @follow_events = Event.where(user_id: follow_users).limit(6)
      end

    # いいね数ランキングの記述
    @event_like_ranking = Event.find(Like.group(:event_id).order('count(event_id) desc').limit(6).pluck(:event_id))

    # 参加人数ランキングの記述
    @event_join_ranking = Event.find(JoinUser.group(:event_id).order('count(event_id) desc').limit(6).pluck(:event_id))

    # ユーザーの参加数ランキングの記述
    @user_join_ranking = User.find(JoinUser.group(:user_id).order('count(user_id) desc').limit(9).pluck(:user_id))

    # ユーザーの主催数ランキングの記述
    @user_event_ranking = User.find(Event.group(:user_id).order('count(user_id) desc').limit(9).pluck(:user_id))
  end

  private

  def event_params
    params.require(:event).permit(:title, :content, :start_time, :prefecture, :address, :image, :image_cache, :remove_image, :tag_list, :latitude, :longitude)
  end

end
