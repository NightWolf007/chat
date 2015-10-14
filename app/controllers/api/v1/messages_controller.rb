class Api::V1::MessagesController < ApplicationController

  def index
    unless params[:room_id]
      return render status: :bad_request, json: {}
    end

    room = RModels::Room.find params[:room_id]
    unless room
      return render status: :not_found, json: {}
    end 

    if current_user
      uid = current_user
    elsif params[:user] && params[:user][:id]
      uid = params[:user][:id]
    else
      return render status: :forbidden, json: {}
    end

    unless room.allowed_plain.include? uid
      return render status: :forbidden, json: {}
    end

    render json: room.messages
  end
end