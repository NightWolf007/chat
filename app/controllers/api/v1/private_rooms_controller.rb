class Api::V1::PrivateRoomsController < ApplicationController

  def show
    uid = current_user ? current_user.id : SecureRandom.hex(5)
    uname = current_user ? current_user.name : params[:name]

    return render(status: :bad_request, json: {}) unless uname

    GetPrivateRoom.new(self, params[:id], uid, uname).execute
  end

  def room_not_found
    render status: 404, json: {}
  end

  def create
    uid = current_user ? current_user.id : SecureRandom.hex(5)
    uname = current_user ? current_user.name : params[:name]
    
    return render(status: :bad_request, json: {}) unless uname

    CreatePrivateRoom.new(self, uid, uname).execute
  end

  def room_success(room_id, uid)
    render json: { room: { id: room_id }, user: { id: uid } }
  end
end