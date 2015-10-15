module RModels

  class Room

    attr_accessor :id

    class << self

      def find(id)
        new(id: id) if exists id
      end

      def exists(id)
        $redis.exists "#{RModels::User::TABLE_ALLOWED}:#{id}"
      end

    end

    def initialize(options={})
      @id = options.fetch :id, SecureRandom.hex(4)
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

    def allowed
      RModels::User.allowed @id
    end

    def allowed_json
      RModels::User.allowed_json @id
    end

    def allowed_plain
      RModels::User.allowed_plain @id
    end

    def allow(user)
      user.allow @id
    end

    def uname_exists?(name)
      RModels::User.allowed_json(@id).values.index { |u| u['name'] == name }
    end

    def persist
      $redis.persist "#{RModels::User::TABLE_ALLOWED}:#{@id}"
      $redis.persist "#{RModels::Message::TABLE_NAME}:#{@id}"
    end

    def expire(ttl)
      $redis.expire "#{RModels::User::TABLE_ALLOWED}:#{@id}", ttl
      $redis.expire "#{RModels::Message::TABLE_NAME}:#{@id}", ttl
    end
  end
end