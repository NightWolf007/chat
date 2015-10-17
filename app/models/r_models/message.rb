module RModels

  class Message

    attr_accessor :id, :text, :timestamp, :user_id, :room_id

    TABLE_NAME = 'messages'

    class << self

      # get all by room id
      def select(rid)
        Message.select_json(rid).map do |jmsg| 
          new(id: jmsg['id'], text: jmsg['text'], 
              timestamp: jmsg['timestamp'], 
              room_user_id: jmsg['room_user'], room_id: jmsg['room_id'])
        end
      end

      def select_json(rid)
        Message.select_plain(rid).map do |smsg|
          JSON.parse smsg
        end
      end

      def select_plain(rid)
        $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
      end

      def create(options={})
        Message.new(options).save
      end

    end

    def initialize(options={})
      @id = options.fetch :id, SecureRandom.hex(6)
      @text = options.fetch :text
      @timestamp = options.fetch :timestamp, Time.now
      @room_user_id = options.fetch :room_user_id
      @room_id = options.fetch :room_id
    end

    def room_user
      RoomUser.find_by_ids @user_id, @room_id
    end

    def room
      Room.find @room_id
    end

    def save
      $redis.rpush "#{TABLE_NAME}:#{@room_id}", to_json
      return self
    end

    def to_json
      JSON.generate id: @id, text: @text, timestamp: @timestamp, room_user: @room_user_id
    end
  end

end