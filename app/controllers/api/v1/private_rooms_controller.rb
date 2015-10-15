class Api::V1::PrivateRoomsController < ApplicationController

  def show
    GetPrivateRoom.new(self, params[:id], current_user).execute
  end

  def room_not_found
    render status: 404, json: {}
  end

  def create
    CreatePrivateRoom.new(self, current_user).execute
  end

  def room_success(room_id, uid)
    render json: { room: { id: room_id }, user: { id: uid } }
  end

end