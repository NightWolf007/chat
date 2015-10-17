class Api::V1::MessagesController < ActionController::Base

  def index
    return render status: :bad_request, json: {} unless params[:room_id]

    room = RModels::Room.find params[:room_id]
    return render status: :not_found, json: {} unless room

    return render status: :forbidden, json: {} unless current_user || request.headers['SessionToken']

    user = RModels::User.find(request.headers['SessionToken'])
    return render status: :forbidden, json: {} unless user && RModels::RoomUser.find_by_ids(user.id, params[:room_id])

    render json: room.messages_json
  end
end