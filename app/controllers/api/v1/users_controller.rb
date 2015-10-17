class Api::V1::UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [ :show, :auth ]

  def show
    @user = User.find(params[:id])
    if current_user && current_user.id == @user.id
      render json: @user, serializer: CurrentUserSerializer
    else
      render json: @user
    end
  end

  def me
    @user = User.find(current_user.id)
    render json: @user
  end

  def update
    @user = User.find params[:id]
    if current_user.id != @user.id
      render :status => 403, :json => {}
      return nil
    end

    unless params.has_key?(:user)
      render status: 400, json: { errors: "User can't be blank" }
      return nil
    end

    if params[:user].has_key?(:img)
      params[:user][:image] = UploadAvatar.new(params[:user][[:img]]).execute
      params[:user].delete(:img)
    else
      params[:user][:image] = nil
    end

    if @user.update_attributes user_params
      render json: @user
    else
      render :status => 422, :json => { errors: @user.errors.full_messages }
    end
  end

  def destroy
    @user = User.find params[:id]
    if current_user.id != @user.id
      render :status => 403, :json => {}
      return nil
    end
    @user.destroy
    render :json => @user
  end

  private

  def user_params
    params.require(:user).permit(:name, :password, :gender, :birthday, :location, :img)
  end
end