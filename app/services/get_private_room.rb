class GetPrivateRoom

  def initialize(context, room_id, current_user=nil)
    @context, @room_id = context, room_id
    uid = current_user ? current_user.id : SecureRandom.hex(5)
    @user = RModels::User.new(id: uid, ip: @context.request.remote_ip)
  end

  def execute
    room = RModels::Room.find room_id
    if room
      room.allow(@user)
      @context.room_success room_id, @user.id
    else
      @context.room_not_found room_id
    end
  end

  private

  def generate_s(len)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(len) { charset.sample }.join
  end
end