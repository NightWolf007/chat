class CreatePrivateRoom

  def initialize(context)
    @context = context
  end

  def execute
    # @context.room_exists(key) if RModels::Room.exists key
    room = RModels::Room.create
    @context.room_success room.id
  end
end