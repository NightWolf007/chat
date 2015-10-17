class Api::V1::PrivateRoomsController < ApplicationController

  def show
    return render json: { privateRoom: { id: params[:id] } } if RModels::Room.exists params[:id]
    render status: :not_found, json: {}
  end

  def user_success(uid, image)
    render json: { data: { type: 'room_user', id: uid, image: image } }
  end

  def room_not_found
    render status: 404, json: {}
  end

  def create
    return render status: :bad_request, json: {} unless current_user || request.headers['SessionToken']
    return render status: :forbidden, json: {} unless RModels::User.exists(request.headers['SessionToken'])
    CreatePrivateRoom.new(self).execute
  end

  def room_success(room_id)
    render json: { privateRoom: { id: room_id } }
  end

  def room_exists(room_id)
    render(status: :bad_request, json: { error: "Room #{room_id} already exists" })
  end
end