class RMessage

  TABLE_NAME = 'messages'

  class << self

    # get all by room id
    def select(rid)
      srooms = $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
      srooms.map do |sroom|
        jroom = JSON.parse sroom
        new jroom[:text], jroom[:timestamp], jroom[:user_id], rid
      end
    end

    def jselect(rid)
      $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
      srooms.map do |sroom|
        JSON.parse sroom
      end
    end

    def sselect(rid)
      $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
    end

  end

  def initialize(text, timestamp, user_id, room_id, id = SecureRandom.generate 6)
    @id = id
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