class CreatePrivateRoom

  def initialize(context)
    @context = context
  end

  def execute
    key = generate_s 6
    @context.room_exists(key) if RModels::Room.exists key
    RModels::Room.create key
    @context.room_success key
  end

  private

  def generate_s(len)
    charset = Array('A'..'Z') + Array('a'..'z')
    Array.new(len) { charset.sample }.join
  end
end