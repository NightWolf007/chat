module RModels

  class User

    attr_accessor :id, :ip #, :name, :gender, :age, :location

    TABLE_NAME = 'users'
    # TABLE_ALLOWED = 'allowed'
    # TABLE_BLOCKED = 'blocked'

    class << self

      def create(options={})
        User.new(options).save
      end

      def find(id)
        return nil unless User.exists(id)
        ip = $redis.hget "#{TABLE_NAME}:#{id}", 'ip'
        User.new(id: id, ip: ip)
      end

      def exists(id)
        $redis.exists "#{TABLE_NAME}:#{id}"
      end

      def all
        all_ids.map do |id|
          ip = $redis.hget "#{TABLE_NAME}:#{id}", 'ip'
          User.new(id: id, ip: ip)
        end
      end

      def all_ids
        keys = $redis.keys "#{TABLE_NAME}:*"
        keys.map do |k|
          k = k[TABLE_NAME.length+1..-1]
        end
      end
    end

    def initialize(options={})
      @id = options.fetch :id, SecureRandom.hex(5)
      @ip = options.fetch :ip
    end

    def save
      $redis.hset "#{TABLE_NAME}:#{@id}", 'ip', @ip
      return self
    end

    def expire(ttl)
      $redis.expire "#{TABLE_NAME}:#{@id}", ttl
    end

    def persist
      $redis.persist "#{TABLE_NAME}:#{@id}"
    end
  end

end