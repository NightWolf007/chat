class Api::V1::RoomUsersController < ApplicationController

  def show
    @room_user = RModels::RoomUser.find params[:id]
    return render status: :not_found, json: {} unless @room_user
  end

  def create
    return render status: :bad_request, json: {} unless params[:roomUser]
    return render status: :forbidden, json: {} unless current_user || request.headers['SessionToken']
    return render status: :forbidden, json: {} unless RModels::User.exists(request.headers['SessionToken'])

    uname = current_user ? current_user.name : params[:roomUser][:name]
    return render(status: :bad_request, json: {}) unless uname && params[:roomUser][:room]
    return render(status: :not_found, json: {}) unless RModels::Room.exists params[:roomUser][:room]

    if current_user
      @room_user = RModels::RoomUser.create(room_id: params[:roomUser][:room], user_id: request.headers['SessionToken'],
                                          name: uname, image: current_user.image,
                                          gender: current_user.gender, age: current_user.age, location: current_user.location)
    else
      @room_user = RModels::RoomUser.create(room_id: params[:roomUser][:room], user_id: request.headers['SessionToken'],
                                          name: uname, image: generate_image)
      p @room_user.id
    end
  end

  private

  def generate_image
    files = Dir.entries(Rails.root.join(ENV['AVATARS_DIR']))
    files -= ['.', '..']
    files.sample
  end
end