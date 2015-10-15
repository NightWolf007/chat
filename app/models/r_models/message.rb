module RModels

  class Message

    attr_accessor :id, :text, :timestamp, :user_id, :room_id

    TABLE_NAME = 'messages'

    class << self

      # get all by room id
      def select(rid)
        smsgs = $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
        smsgs.map do |smsg|
          jmsg = JSON.parse smsg
          new(id: jmsg['id'], text: jmsg['text'], 
              timestamp: jmsg['timestamp'], 
              user_id: jmsg['user_id'], room_id: jmsg['room_id'])
        end
      end

      def select_json(rid)
        $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
        smsgs.map do |smsg|
          JSON.parse smsg
        end
      end

      def select_plain(rid)
        $redis.lrange "#{TABLE_NAME}:#{rid}", 0, -1
      end

    end

    def initialize(options={})
      @id = options.fetch :id, SecureRandom.hex(6)
      @text = options.fetch :text
      @timestamp = options.fetch :timestamp, Time.now
      @user_id = options.fetch :user_id
      @room_id = options.fetch :room_id
    end

    def user
      RModels::User.find @room_id, @user_id
    end

    def room
      RModels::Room.find @room_id
    end

    def save
      $redis.rpush "#{TABLE_NAME}:#{@room_id}", to_json
    end

    def to_json
      JSON.generate id: @id, text: @text, timestamp: @timestamp, user_id: @user_id
    end
  end

end