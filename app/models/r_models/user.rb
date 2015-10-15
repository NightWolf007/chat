module RModels

  class User

    attr_accessor :id, :ip, :gender, :age, :location

    TABLE_ALLOWED = 'allowed'
    TABLE_BLOCKED = 'blocked'

    class << self

      # get all by room id
      def allowed(rid)
        p rid
        sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
        sallowed.map do |key|
          suser = $redis.hget "#{TABLE_ALLOWED}:#{rid}", key
          juser = JSON.parse suser
          new(id: key, ip: juser['ip'], gender: juser['gender'],
              age: juser['age'], location: juser['location'])
        end
      end

      def allowed_json(rid)
        allowed = {}
        sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
        sallowed.each do |key|
          allowed[key] = JSON.parse($redis.hget "#{TABLE_ALLOWED}:#{rid}", key)
        end
      end

      def allowed_plain(rid)
        allowed = {}
        sallowed = $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
        sallowed.each do |key|
          allowed[key] = $redis.hget "#{TABLE_ALLOWED}:#{rid}", key
        end
      end

      def allowed_ids(rid)
        $redis.hkeys "#{TABLE_ALLOWED}:#{rid}"
      end

    end

    def initialize(options={})
      @id = options.fetch :id, SecureRandom.hex(4)
      @ip = options.fetch :ip
      @gender = options[:gender]
      @age = options[:age]
      @location = options[:location]
    end

    def allow(rid)
      $redis.hset "#{TABLE_ALLOWED}:#{rid}", @id, to_json
    end

    def to_json
      JSON.generate ip: @ip, gender: @gender, age: @age, location: @location
    end
  end

end