module RModels

  TABLE_NAME = "rooms"

  class Room

    attr_accessor :id

    class << self

      def find(id)
        room = $redis.get "#{TABLE_NAME}:#{id}"
        new(id: id) if room
      end

      def exists(id)
        $redis.exists "#{TABLE_NAME}:#{id}"
      end

      def create(options={})
        new(options).save
      end

    end

    def initialize(options={})
      @id = options.fetch :id, generate_s(6)
    end

    def empty?
      RModels::RoomUser.select_by_room.empty?
    end

    def messages
      RModels::Message.select @id
    end

    def messages_json
      RModels::Message.select_json @id
    end

    def messages_plain
      RModels::Message.select_plain @id
    end

    def blocked_ids
      []
    end

    def save
      $redis.set "#{TABLE_NAME}:#{@id}", 1
      return self
    end

    def expire(ttl)
      $redis.expire "#{TABLE_NAME}:#{@id}", ttl
      $redis.expire "#{RModels::Message::TABLE_NAME}:#{@id}", ttl
    end

    def persist
      $redis.persist "#{TABLE_NAME}:#{@id}"
      $redis.persist "#{RModels::Message::TABLE_NAME}:#{@id}"
    end

    private

    def generate_s(len)
      charset = Array('A'..'Z') + Array('a'..'z')
      Array.new(len) { charset.sample }.join
    end
  end
end