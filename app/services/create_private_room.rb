class CreatePrivateRoom

  def initialize(context, current_user=nil)
    @context = context
    uid = current_user ? current_user.id : SecureRandom.hex(5)
    @user = RUser.new id: uid, ip: @context.request.remote_ip
  end

  def execute
    key = generate_s(6)
    RRoom.new(id: key).allow(@user)
    @context.create_success key, @user.id
  end

  private

  def generate_s(len)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(len) { charset.sample }.join
  end
end