class Api::V1::AnonymousRoomsController < ApplicationControler

  def create
    Services::CreateRoom(params, self).execute
  end

  def show
    if $redis.exists params[:id]
      render :json => {room: {id: params[:id]}}
    else
      render :status => 404, :json => []
    end
  end
end