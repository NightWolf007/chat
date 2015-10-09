class Api::V1::UsersController < ApplicationController
  before_filter :authenticate_user!, :except => :show

  def show
    @user = User.find(params[:id])
    @detailed = (current_user && current_user.id.to_s == params[:id])
  end

  def me
    @user = User.find(current_user.id)
    @detailed = true
    render :show
  end

  def update
    if current_user.id.to_s != params[:id]
      render :status => 403, :json => []
      return nil
    end
    @user = User.find params[:id]
    if @user.update_attributes user_params
      @detailed = true
      render :show
    else
      render :status => 422, :json => { errors: @user.errors.full_messages }
    end
  end

  def destroy
    if current_user.id.to_s != params[:id]
      render :status => 403, :json => []
      return nil
    end
    user = User.find params[:id]
    user.destroy
    render :json => []
  end

  private

  def user_params
    params.require(:user).permit(:name, :password, :sex, :birthday, :location)
  end
end