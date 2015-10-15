class GetPrivateRoom

  def initialize(context, room_id, uid, uname)
    @context, @room_id, @uid, @uname = context, room_id, uid, uname
  end

  def execute
    room = RModels::Room.find @room_id
    if room
      user = init_user
      room.allow(user)
      @context.user_success user.id
    else
      @context.room_not_found @room_id
    end
  end

  private

  def init_user
    RModels::User.new(id: @uid, ip: @context.request.remote_ip, name: @uname)
  end
end