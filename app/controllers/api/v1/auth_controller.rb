class Api::V1::AuthController < ApplicationController

  def create
    user = RModels::User.new(ip: request.remote_ip)
    return render json: { data: { type: 'user', id: user.save.id } } unless current_user
    user[:id] = current_user.authentication_token
    render json: user.save
  end
end