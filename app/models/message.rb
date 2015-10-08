class RMessage

  TABLE_NAME = 'messages'

  class << self

    # get all by room id
    def select(rid)
      srooms = $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
      srooms.map do |sroom|
        jroom = JSON.parse sroom
        jroom[:room_id] = rid
        new jroom
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

  def initialize(options={})
    @id = options.fetch :id, SecureRandom.generate(6)
    @text = options.fetch :text
    @timestamp = options.fetch :timestamp
    @user_id = options.fetch :user_id
    @room_id = options.fetch :room_id
  end

  def user
    User.find @user_id
  end

  def room
    Room.find @room_id
  end
end