class RMessage

  def initialize(text, timestamp, user_id, room_id)
    @id = SecureRandom.generate 5
    @text = text
    @timestamp = timestamp
    @user_id = user_id
    @room_id = room_id
  end

  def user
  end

  def room
    Room.find room_id
  end
end