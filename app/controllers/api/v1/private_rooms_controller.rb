class Api::V1::PrivateRoomsController < ApplicationController

  def show
    uid = current_user ? current_user.id : SecureRandom.hex(5)
    uname = current_user ? current_user.name : params[:name]

    return render(status: :bad_request, json: {}) unless uname

    GetPrivateRoom.new(self, params[:id], uid, uname).execute
  end

  def user_success(uid)
    render json: { user: { id: uid } }
  end

  def room_not_found
    render status: 404, json: {}
  end

  def create 
    CreatePrivateRoom.new(self).execute
  end

  def room_success(room_id)
    render json: { privateRoom: { id: room_id } }
  end

  def room_exists(room_id)
    render(status: :bad_request, json: { error: "Room #{room_id} already exists" })
  end
end