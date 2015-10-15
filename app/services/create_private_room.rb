class CreatePrivateRoom

  def initialize(context, uid, uname)
    @context, @uid, @uname = context, uid, uname
  end

  def execute
    key = generate_s(6)
    user = init_user
    RModels::Room.new(id: key).allow(user)
    @context.room_success key, user.id
  end

  private

  def init_user
    RModels::User.new(id: @uid, ip: @context.request.remote_ip, name: @uname)
  end

  def generate_s(len)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(len) { charset.sample }.join
  end
end