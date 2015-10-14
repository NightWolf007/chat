class Api::V1::PrivateRoomsController < ApplicationController

  def create
    CreatePrivateRoom.new(self, current_user).execute
  end

  def create_success(key, uid)
    render json: { room: { id: key }, user: { id: uid } }
  end

  def show
    if RModels::Room.exists params[:id]
      render json: { room: { id: params[:id] } }
    else
      render status: 404, json: {}
    end
  end
end